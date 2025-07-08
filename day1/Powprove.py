import hashlib
import time

# 实践 POW， 编写程序（编程语言不限）用自己的昵称 + nonce，不断修改nonce 进行 sha256 Hash 运算：
#   直到满足 4 个 0 开头的哈希值，打印出花费的时间、Hash 的内容及Hash值。
#   再次运算直到满足 5 个 0 开头的哈希值，打印出花费的时间、Hash 的内容及Hash值。


# 参数：name: 你的昵称，leading_zeros: 目标哈希值前导零的数量
def pow_prove(name, leading_zeros):
    nonce = 0;
    target_Difficulty = '0' * leading_zeros  # 目标难度，4个或5个0开头
    start_time = time.time()  # 记录开始时间,用于后面计算找 nonce所花费的时间

    # 不断调整 nonce ，直到满足条件：Hash <= target_Difficulty(同一个意思前导零数量 >= leading_zeros)
    while True:
        # 拼接昵称 ＋ nonce
        input_string = f"{name}{nonce}"
        
        # 根据拼接昵称 ＋ nonce 计算哈希值，并调用 hexdigest() 函数将二进制转发为十六进制字符串
        hash_result = hashlib.sha256(input_string.encode()).hexdigest()

        # 判断哈希值是否满足条件：Hash <= target_Difficulty(同一个意思前导零数量 >= leading_zeros)
        if hash_result.startswith(target_Difficulty):
            # 如果满足条件，打印结果
            end_time = time.time()  # 记录结束时间
            spend_time = end_time - start_time
            print(f"spend_time:{spend_time}, hash_content: {input_string}, Hash_result: {hash_result}, ")
            break
            # break spend_time;
        nonce = nonce + 1;

# 我的昵称
name = "Tim"
# 调用函数寻找4个0开头的哈希值
pow_prove(name, 4)
# 调用函数寻找5个0开头的哈希值
pow_prove(name, 5)


# ------------------------------------  增加一个0，寻找nonce消耗time    ------------------------------- 

# time_4zeros = pow_prove(name, 4)
# time_5zeros = pow_prove(name, 5)

# # 计算时间增长比例
# if time_4zeros > 0:
#     ratio = time_5zeros / time_4zeros
#     print(f"\n4个0到5个0，计算时间增长了约 {ratio:.1f} 倍")