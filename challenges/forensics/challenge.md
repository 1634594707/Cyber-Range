# 🔍 取证挑战 — 网络流量分析

## challenge.yml
```yaml
name: "流量分析 — 找到泄露的数据"
category: Forensics
difficulty: Easy
points: 150
hints:
  - cost: 10
    text: "Wireshark 中 Follow TCP Stream 可以查看完整会话"
  - cost: 20
    text: "HTTP 流量是明文的，关注 POST 请求"
  - cost: 20
    text: "导出 HTTP 对象: File → Export Objects → HTTP"
flag: "CTF{p4ck3t_wh1sp3r3r_f0und_m3}"
```

## 题目描述
```
# 流量分析 — 找到泄露的数据

**难度**: ⭐ Easy | **分数**: 150

## 场景
安全团队捕获了一段可疑的网络流量，怀疑有人在向外传输敏感数据。
分析 pcap 文件，找到泄露的内容。

## 附件
- [suspicious_traffic.pcap](./suspicious_traffic.pcap)

## 需要回答
1. 攻击者的 IP 地址是什么？
2. 敏感数据通过什么协议传输？
3. Flag 是什么？
```

## 出题数据生成 (Python)
```python
"""
用 scapy 生成 challenge pcap
pip install scapy
"""
from scapy.all import *

# HTTP 正常流量 + 隐藏的 flag
packets = []

# 正常浏览流量
packets += [IP(dst="192.168.1.100")/TCP(dport=80)/Raw(load="GET / HTTP/1.1\r\nHost: example.com\r\n\r\n")]
packets += [IP(src="192.168.1.100")/TCP(sport=80)/Raw(load="HTTP/1.1 200 OK\r\n\r\n<html>OK</html>")]

# 泄露的 flag（隐藏在 POST 请求中）
packets += [IP(dst="192.168.1.100")/TCP(dport=80)/Raw(
    load="POST /upload HTTP/1.1\r\nHost: example.com\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 41\r\n\r\ndata=CTF{p4ck3t_wh1sp3r3r_f0und_m3}"
)]

wrpcap("suspicious_traffic.pcap", packets)
print("[+] Generated: suspicious_traffic.pcap")
```
