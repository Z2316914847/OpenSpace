import hashlib
import time

def pow_example(nickname, leading_zeros):
    print(f"\n开始寻找 {leading_zeros} 个 0 开头的哈希值...")
    start_time = time.time()
    nonce = 0
    
    while True:
        input_str = f"{nickname}{nonce}"
        hash_result = hashlib.sha256(input_str.encode()).hexdigest()
        
        if hash_result.startswith('0' * leading_zeros):
            end_time = time.time()
            elapsed = end_time - start_time
            print(f"找到符合条件的哈希值！")
            print(f"输入内容: {input_str}")
            print(f"哈希值: {hash_result}")
            print(f"耗时: {elapsed:.4f} 秒")
            print(f"尝试次数: {nonce + 1}")
            return elapsed
        
        nonce += 1

# 我的昵称
nickname = "AI助手"

# 先找4个0开头的哈希值
time_4zeros = pow_example(nickname, 4)

# 再找5个0开头的哈希值
time_5zeros = pow_example(nickname, 5)

# 计算时间增长比例
if time_4zeros > 0:
    ratio = time_5zeros / time_4zeros
    print(f"\n从4个0到5个0，计算时间增长了约 {ratio:.1f} 倍")