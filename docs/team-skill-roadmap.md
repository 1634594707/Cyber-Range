# 🚀 团队技能提升路线图 — Cyber Range Team

> 目标：3个月从基础运维到自主出题的高级安全团队

## 📅 Phase 1: 基础建设期（第1-4周）

### 第1周：平台上手 & 基础安全概念
| 技能项 | 学习目标 | 考核方式 |
|--------|----------|----------|
| Linux 基础 | 熟练使用命令行、文件操作、权限管理 | 完成 10 道 Linux 基础题 |
| 网络基础 | TCP/IP、HTTP/HTTPS、DNS 原理 | 用 Wireshark 分析一次完整 HTTP 请求 |
| CTFd 平台操作 | 注册、组队、提交 flag、查看排行 | 成功提交 3 道入门题 |
| Docker 基础 | 镜像、容器、docker-compose 概念 | 成功运行一个自定义 Docker 容器 |

### 第2周：Web 安全入门
| 技能项 | 学习目标 | 考核方式 |
|--------|----------|----------|
| HTTP 抓包 | Burp Suite / 浏览器 DevTools | 抓取并修改一个 HTTP 请求 |
| XSS 基础 | 理解反射型/存储型/DOM 型 XSS | 完成 XSS Lab 挑战 |
| SQL 注入基础 | Union注入、布尔盲注、时间盲注 | 完成 SQLi Lab 挑战 |
| 文件上传漏洞 | 绕过前端/后端校验 | 完成 File Upload 挑战 |

### 第3周：密码学 & 编码
| 技能项 | 学习目标 | 考核方式 |
|--------|----------|----------|
| 常见编码 | Base64/32/16、URL编码、Morse | 解码 5 种编码的混合字符串 |
| 古典密码 | 凯撒、维吉尼亚、栅栏密码 | 完成 Crypto 入门挑战 |
| Hash 基础 | MD5、SHA 家族、加盐 | 使用 hashcat 破解简单 Hash |
| RSA 入门 | 理解公钥/私钥、简单数学攻击 | 完成 RSA 基础题 |

### 第4周：综合练习 & 复盘
- 组织一次团队内部 Mini-CTF（8-10 题）
- 每人讲解一道自己解出的题目
- 整理解题方法论文档

---

## 📅 Phase 2: 能力提升期（第5-8周）

### 第5-6周：进阶 Web 安全
- SSRF（服务端请求伪造）利用链
- 反序列化漏洞（PHP/Java/Python）
- 模板注入（SSTI）
- JWT 攻击技术
- OAuth 2.0 安全风险

### 第7周：二进制入门
- x86/x64 汇编基础
- GDB/Pwndbg 调试器使用
- 栈溢出原理与 ROP
- 格式化字符串漏洞

### 第8周：红队技术
- 信息收集方法论
- 内网渗透基础
- 权限提升技术
- 横向移动技巧

---

## 📅 Phase 3: 出题 & 研究期（第9-12周）

### 第9-10周：出题方法论
- 如何设计一个好的 CTF 题目
- 题目难度控制与提示设计
- Docker 环境搭建最佳实践
- 源码审计技巧

### 第11-12周：独立出题 & 赛事组织
- 每人独立出 2-3 道题目
- 团队交叉审核（按 challenge-dev-guide.md 清单）
- 组织对外公开 CTF 赛事
- 赛后 Writeup 整理与发布

---

## 📚 推荐资源

### 在线平台
| 平台 | 网址 | 适合阶段 |
|------|------|----------|
| PortSwigger Academy | https://portswigger.net/web-security | Phase 1-2 |
| HackTheBox | https://hackthebox.com | Phase 2-3 |
| TryHackMe | https://tryhackme.com | Phase 1-2 |
| CTFtime | https://ctftime.org | 全阶段 |
| Pwnable.kr | https://pwnable.kr | Phase 2 |

### 必读书籍
1. 《Web安全攻防：渗透测试实战指南》
2. 《白帽子讲Web安全》— 吴翰清
3. 《加密与解密》第4版
4. 《0day安全：软件漏洞分析技术》

### 工具清单
```bash
# Web
Burp Suite Community | OWASP ZAP | sqlmap | dirsearch | ffuf

# 逆向
IDA Free | Ghidra | radare2 | x64dbg

# 密码学
CyberChef | RsaCtfTool | hashcat | John the Ripper

# 二进制
pwntools | GDB + pwndbg | checksec | ROPgadget

# 取证
Wireshark | Volatility | binwalk | foremost | exiftool
```

---

## 📊 技能矩阵追踪

```
团队成员: ________  日期: ________

技能领域          当前水平(1-5)  目标水平  提升计划
─────────────────────────────────────────────────
Linux 运维           [ ]           [ ]      ______
Docker               [ ]           [ ]      ______
Web 安全 - XSS       [ ]           [ ]      ______
Web 安全 - SQLi      [ ]           [ ]      ______
Web 安全 - SSRF      [ ]           [ ]      ______
Web 安全 - RCE       [ ]           [ ]      ______
逆向工程             [ ]           [ ]      ______
密码学               [ ]           [ ]      ______
二进制漏洞           [ ]           [ ]      ______
流量分析             [ ]           [ ]      ______
Python 脚本          [ ]           [ ]      ______
Docker 出题          [ ]           [ ]      ______

评分标准: 1=听说过 | 2=会基本操作 | 3=能独立解题 | 4=能出题 | 5=能教学
```

---

## 🏆 激励与考核

### 月度考核
- 月底进行一次能力评估
- 积分制：解一题 +1分，出一题 +5分，做一次技术分享 +3分

### 季度里程碑奖励
- 完成 Phase 1: Cyber Range 初级安全工程师认证
- 完成 Phase 2: 入选团队红队预备成员
- 完成 Phase 3: 获得出题资格，带队参加外部 CTF
