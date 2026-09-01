import random
import h5py
import numpy as np

kernel_weights = []
for i in range(2048):
    num = random.randint(-2**3, 2**3 - 1)
    if num < 0:
        # 负数，计算补码
        weight = format((1 << 16) + num, '016b')
    else:
        # 正数，直接转换
        weight = format(num, '016b')
    kernel_weights.append(weight)##产生6个卷积核的150个权重

bias = []
for i in range(64):
    num = random.randint(-2**4, 2**4 - 1)
    if num < 0:
        # 负数，计算补码
        bia = format((1 << 40) + num, '040b')
    else:
        # 正数，直接转换
        bia = format(num, '040b')
    bias.append(bia)##产生6个卷积核的150个权重


with h5py.File('/Users/zuohaonan/Desktop/NN_accelerator/minst_CNN_weights04.h5','w') as file:
    file.create_dataset('kernel_weights',data = kernel_weights)
    file.create_dataset('bias', data=bias)
    # file.create_dataset('pool_weights', data=pool_weights)
    # file.create_dataset('pool_bias', data=pool_bias)
    file.close()  # 手动关闭文件