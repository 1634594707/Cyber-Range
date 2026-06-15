# 🔐 密码学挑战 — RSA 入门

## challenge.yml
```yaml
name: "RSA 入门 — 小指数攻击"
category: Crypto
difficulty: Easy
points: 150
hints:
  - cost: 10
    text: "公钥指数 e 很小（e=3），明文也很短"
  - cost: 20
    text: "如果 m^e < n，可以直接开立方根"
flag: "CTF{rsa_l0w_3xp0n3nt_5uck5}"
```

## 题目描述
```
# RSA 入门 — 低加密指数攻击

**难度**: ⭐ Easy | **分数**: 150

## 场景
一段重要的消息被 RSA 加密了，但加密的实现似乎有问题...

## 附件信息
- n = 18254907644567349123...
- e = 3
- c = 18042375912875312456...

## 提示
当 e 很小且明文很短时，m^e 可能小于 n，此时密文就是 m^e。
```

## 出题脚本 (Python)
```python
from Crypto.Util.number import getPrime, bytes_to_long, long_to_bytes

# 生成 RSA 参数
p = getPrime(512)
q = getPrime(512)
n = p * q
e = 3  # 故意使用小指数

flag = b"CTF{rsa_l0w_3xp0n3nt_5uck5}"
m = bytes_to_long(flag)

# 加密
c = pow(m, e, n)

# 由于 m 很短，m^3 < n，所以 c = m^3（没有取模效果！）
assert c == pow(m, e)  # 这是漏洞！

print(f"n = {n}")
print(f"e = {e}")
print(f"c = {c}")
print(f"\n# Verify: m^3 {'<' if m**3 < n else '>='} n")

# 解题只需: from gmpy2 import iroot; iroot(c, 3)
```
