# 🔐 逆向工程挑战 — 简单 XOR

## challenge.yml
```yaml
name: "RE 入门 — XOR 加密破解"
category: Reverse
difficulty: Easy
points: 150
hints:
  - cost: 10
    text: "看看二进制文件中是否包含硬编码密钥"
  - cost: 20
    text: "strings 命令可以提取可打印字符"
  - cost: 20
    text: "密钥长度是 4 字节，用 XOR 特性推导"
flag: "CTF{x0r_c4n_b3_t00_e4sy}"
```

## 题目描述
```
# RE 入门 — XOR 加密破解

**难度**: ⭐ Easy | **分数**: 150

## 场景
你获得了一个被加密的文件 `flag.enc` 和加密程序 `encrypt`。
已知加密算法是简单的 XOR，能找到密钥并解密吗？

## 附件
- [encrypt](./encrypt) - Linux ELF 可执行文件
- [flag.enc](./flag.enc) - 加密后的文件

## 提示
1. XOR 加密的逆运算还是 XOR
2. Hint: 已知 CTF flag 格式以 `CTF{` 开头
```

## 出题源码 (C)
```c
// encrypt.c — 编译: gcc -o encrypt encrypt.c -s
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
    // 密钥嵌入在二进制中
    unsigned char key[] = {0x4B, 0x33, 0x59, 0x21};  // "K3Y!"
    
    FILE *in = fopen("flag.txt", "r");
    FILE *out = fopen("flag.enc", "w");
    
    unsigned char buf[256];
    size_t len = fread(buf, 1, 256, in);
    
    for (size_t i = 0; i < len; i++) {
        buf[i] ^= key[i % 4];
    }
    
    fwrite(buf, 1, len, out);
    fclose(in); fclose(out);
    return 0;
}
```

## 解题思路 (Writeup)
```
1. strings encrypt | grep -E '^.{1,8}$'  # 查找短字符串
2. 已知明文攻击: flag.enc[0] ^ 'C' = key[0]
   计算出 4 字节密钥
3. 用密钥解密整个文件得到 flag
```
