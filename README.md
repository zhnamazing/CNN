**基于FPGA的稀疏跳过CNN加速器模块**

+ Conv和FC目录分别存储3个卷积层PE和三个全连接层PE的RTL代码
+ python脚本用于产生随机数作为网络第一层的输入和各层权重
+ source_.txt内容为包含参数的flit，用于初始化FPGA的BRAM IP核。
+ Jupyter 脚本读取.h5文件，完成flit数据包的生成用于RTL初始化配置。同时进行卷积运算，并将结果输出至.txt文件中
+ testbench接收RTL模块的要数信号，将数据包flit传入CNN单元并由相应硬件模块完成解包，记录RTL模块的输出并与软件结果对比，相同则拉高标志信号

##### 本设计主要技术点包括：

1）适用于卷积层的一写多读乒乓读写机制，可支持不同卷积步长，实现高效存储访问
2）通过硬件实现sobel边缘检测，将灰度图转换为梯度图，进一步增加输入的稀疏度
3）改进的稀疏激活跳过机制，对于接近0的像素跳过对应访存和计算操作，缩短组合逻辑链的同时避免了高扇出问题

![PE_structures](https://github.com/zhnamazing/CNN/blob/main/Pictures/PE_structures.png?raw=true)

网络模型使用类LeNet；数据集采用CIFAR-100，属于简单分类任务

网络的每个层映射到一个PE，硬件配置包括三个卷积层PE和三个全连接层PE
采用权重固定数据流：权重等参数被预加载到每个PE中，激活则从主存储中读取，计算结果在PE之间传播
网络的激活和权重均存储在BRAM IP中。flit又分为激活flit和权重flit，系统启动后，首先完成权重参数的配置，将对应权重写入MAC中的BRAM，之后将激活输入axon中的bank

![网络规模配置](https://github.com/zhnamazing/CNN/blob/main/Pictures/%E7%BD%91%E7%BB%9C%E8%A7%84%E6%A8%A1%E9%85%8D%E7%BD%AE.png?raw=true)

原始数据为RGB三通道，处理前首先将其转换为灰度图
数据类型采用16位补码有符号数，位宽随运算对应扩展

基于Xilinx Zynq-XC7Z045 FPGA完成了综合（synthesis）-实现（implementation）全流程，并通过了实现后仿真

##### 主要模块说明：

###### 轴突Axon：

包含多个bank，用于缓存输入，其中的pre_sobel模块仅存在于网络的第一层对应的PE中，用于实现Sobel边缘检测预处理操作
边缘检测操作中，对于每个像素点及其周围点，利用x和y型算子进行乘累加运算，得到横向、纵向梯度幅值。之后进行平方和开根操作，得到每个像素点的梯度
使用多个bank存储输入激活，所有bank划分为读区域和写区域，每次一个bank写入新数据的同时，其余bank共同构成读区域以供卷积运算读取，读区域存储的部分输入图行数为在soma中产生一行池化结果所需。
给出（W,H,C）的访存地址，首先计算对应的bank，再得到bank内地址。数据的读取和写入以及bank的读写切换通过状态机控制。
设置掩码寄存器mask，每一位与bank中的数据一一对应，用于标志数据是否为0，后续dendrite访存时据此进行稀疏跳过。

![ping-pong_buffer_previous](C:\Users\LENOVO\Desktop\CNN\Pictures\ping-pong_buffer_previous.png)

###### 树突Dendrite：

存储卷积权重，并从Axon中读取输入。采用卷积核并行，输入复用的策略，每个MAC对应一个卷积核（即一个输出通道），输入数据广播给所有卷积核运算。MAC中的weight_ram用于存储卷积核权重
dendrite生成地址以从axon中获取输入数据，同时产生卷积核权重地址。MAC内经过若干次乘累加运算后，结果经串并转换输出给soma处理
稀疏跳过机制中，利用当前（W,H,C）提前计算最多4个后续访问激活位置，若对应位置掩码为0，即可直接跳过对应访存和计算
为适应上一层的输出数据流，激活各维度的遍历（编址）优先级为：通道—列—行，即先处理同一行同一列的各通道，再转换到同一行的下一列。完成一个卷积窗口运算后，卷积核按照先行后列的方式在输入特征图上移动

![mask_based-jumping](https://github.com/zhnamazing/CNN/blob/main/Pictures/mask_based-jumping.png?raw=true)

###### 胞体Soma：

采用流水线的方式，用于对卷积结果进行加偏置、激活函数运算以及最大池化等卷积后运算

###### 网络接口Mult_NI：

用于完成数据的打包、拆包，实现PE运算部分与外界的通信
