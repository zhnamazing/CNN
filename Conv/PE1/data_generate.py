import random
import h5py
import numpy as np

query_array = []
for i in range(512):
    num = random.randint(-2**3, 2**3 - 1)
    if num < 0:
        # 负数，计算补码
        query = format((1 << 8) + num, '08b')
    else:
        # 正数，直接转换
        query = format(num, '08b')
    query_array.append(query)##产生512个8bitQ值(量化后)

key_array = []
for i in range(32768):
    num = random.randint(-2**3, 2**3 - 1)
    if num < 0:
        # 负数，计算补码
        key = format((1 << 8) + num, '08b')
    else:
        # 正数，直接转换
        key = format(num, '08b')
    key_array.append(key)##产生512×64个8bitK值(量化后)

Q_factor_array = []
for i in range(16):
    num = random.randint(0,3)

    Q_factor_array.append(num)##产生16个Q缩放因子

K_factor_array = []
for i in range(1024):
    num = random.randint(0,3)

    K_factor_array.append(num)##产生16×64个K缩放因子

S_factor_array = []
for i in range(1):
    num = random.randint(0,3)

    S_factor_array.append(num)##产生1个S缩放因子

with h5py.File('C:/Users/zuohaonan/Desktop/graduation_design/Codes/parameter.h5','w') as file:
    file.create_dataset('query_array',data = query_array)
    file.create_dataset('key_array', data=key_array)
    file.create_dataset('Q_factor_array', data=Q_factor_array)
    file.create_dataset('K_factor_array', data=K_factor_array)
    file.create_dataset('S_factor_array', data=S_factor_array)
    file.close()  # 手动关闭文件