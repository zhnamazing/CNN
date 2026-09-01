import random
import h5py
import numpy as np

in_data = []
for i in range(32):
    num = random.randint(-2**3, 2**3 - 1)
    if num < 0:
        # 负数，计算补码
        data = format((1 << 16) + num, '016b')
    else:
        # 正数，直接转换
        data = format(num, '016b')

    in_data.append(data)##产生384位的输入特征图

with h5py.File('/Users/zuohaonan/Desktop/NN_accelerator/data_test04.h5','w') as file:
    file.create_dataset('in_data',data = in_data)
    file.close()  # 手动关闭文件
    