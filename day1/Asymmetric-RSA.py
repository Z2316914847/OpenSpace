import hashlib
import os
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives.serialization import Encoding, PrivateFormat, PublicFormat, NoEncryption
from cryptography.hazmat.primitives.asymmetric.utils import Prehashed

# 非对称加密 RSA 实现：
#   先生成一个公私钥对
#   用私钥对符合 POW 4 个 0 开头的哈希值的 “昵称 + nonce” 进行私钥签名
#       (首先计算出 “昵称 + nonce” 的 Hash_result<= 目标难度，然后用私钥对 “昵称+nonce” 进行签名。这样做的目的：私钥对消息进行签名，然后其他节点用公钥验证签名，验证消息是否被篡改。)
#   用公钥验证
# cryptography 库用法：

def generate_rsa_key_pair():
    # 生成RSA私钥 (公钥指数使用常见的65537，使用2048位密钥长度)
    private_key = rsa.generate_private_key(public_exponent=65537,key_size=2048)

    # 从私钥导出公钥
    public_key = private_key.public_key()
    return public_key, private_key

def find_pow_nonce(name, leading_zeros):
    nonce = 0;
    target_difficulty = '0' * leading_zeros  # 目标难度，4个或5个0开头
    while True:
        # 拼接昵称 ＋ nonce
        name_add_nonce = f"{name}{nonce}"

        # 根据拼接昵称 ＋ nonce 计算哈希值，并调用 hexdigest() 函数将二进制转发为十六进制字符串
        hash_result = hashlib.sha256(name_add_nonce.encode()).hexdigest()

        # 判断哈希值是否满足条件：Hash <= target_Difficulty(同一个意思前导零数量 >= leading_zeros)
        if hash_result.startswith(target_difficulty):
            # 如果满足条件，打印结果
            return name_add_nonce
        nonce = nonce + 1

def signature_with_private_key(private_key, name_add_nonce):
    # 使用SHA-256哈希算法和PKCS1v15填充方案对 “昵称＋nonce” 进行签名
    signature = private_key.sign(name_add_nonce,padding.PKCS1v15(),hashes.SHA256())
    return signature

def public_key_signature_verify(public_key, name_add_nonce, signature):
    # 不是所有返回 bool 的函数都要加 try/except，只有当你预期函数内部可能抛异常时才需要加
    try:   
        result = public_key.verify(signature, name_add_nonce, padding.PKCS1v15(), hashes.SHA256())
        return True
    except Exception as e:
        print(f"Signature verification failed: {e}")
        return False

# 定义一个 main() 函数来组织代码逻辑
def main():
    # 1. 生成 RSA 密钥对：public_key, private_key时两个对象，Python默认只显示它们的内存地址，而不是密钥对的内容。如果你想看到密钥的内容（比如 PEM 格式），可以使用cryptography.hazmat.primitives.serialization模块：
    public_key, private_key = generate_rsa_key_pair()
     # 打印PEM格式的密钥内容
    print(f"use RSR product public key result: {public_key.public_bytes(
        encoding=Encoding.PEM,
        format=PublicFormat.SubjectPublicKeyInfo
    )}")
    print(f"use RSR product private key result: {private_key.private_bytes(
        encoding=Encoding.PEM,
        format=PrivateFormat.PKCS8,
        encryption_algorithm=NoEncryption()
    )}")
    print("\n")
    
    # 2. 寻找一个 nonce 值，使得 "昵称+nonce"的 SHA-256 哈希值以4个0开头
    name = "Tim"
    name_add_nonce = find_pow_nonce(name, 3)
    print(f"name splicing nonce result: {name_add_nonce}")
    print("\n")
    
    # 3. 使用私钥对 "昵称+nonce" 进行签名，使用SHA-256作为哈希算法，使用PKCS1v15作为填充方案
    signature = signature_with_private_key(private_key, name_add_nonce.encode())
    print(f"The result of signature “name_nonce” with the private key : {signature.hex()}")
    print("\n")


    # 4. 使用公钥验证签名，如果验证成功，说明签名有效且消息未被篡改，反正，说明签名无效或消息被篡改
    is_valid = public_key_signature_verify(public_key, name_add_nonce.encode(), signature)
    print(f"Verify the result：{is_valid}")

# 这句话的意思是：只有当这个问价被运行时，才会执行下面代码，这个文件被导入，不会运行下面代码 
if __name__ == "__main__":
    main()