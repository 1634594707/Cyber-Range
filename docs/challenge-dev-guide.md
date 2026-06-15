# 🔐 CTF 挑战开发规范 v1.0

## 1. 挑战分类体系

| 分类       | 标识     | 难度范围 | 典型技能                          |
| ---------- | -------- | -------- | --------------------------------- |
| Web安全    | `web`    | 1-500    | XSS/SQLi/SSRF/RCE/文件上传/逻辑漏洞 |
| 逆向工程   | `rev`    | 1-500    | x86/ARM汇编、反编译、加壳脱壳     |
| 密码学     | `crypto` | 1-500    | 古典密码、RSA/ECC、侧信道        |
| 二进制漏洞 | `pwn`    | 2-500    | 栈溢出、堆利用、格式化字符串     |
| 取证分析   | `forensics` | 1-400 | 流量分析、内存取证、隐写术        |
| 综合       | `misc`   | 1-400    | 编码、协议分析、安全配置          |

## 2. 挑战目录结构标准

```
challenges/{category}/{challenge-name}/
├── challenge.md          # 题目描述（Markdown，含 flag）
├── challenge.yml         # 元数据（名称、分类、难度、分数）
├── Dockerfile            # 容器构建文件
├── docker-compose.yml    # （可选）多容器编排
├── app/                  # 挑战应用源码
│   ├── src/
│   ├── static/
│   └── flag.txt          # ⚠️ 生产部署时替换实际 flag
├── writeup/              # （赛后公开）题解
│   └── solution.md
└── solve/                # （裁判用）自动化验证脚本
    └── check.py
```

## 3. challenge.yml 规范

```yaml
# 必填字段
name: "挑战名称（中文）"
category: web          # web/rev/crypto/pwn/forensics/misc
difficulty: Medium     # Easy/Medium/Hard/Insane
points: 200            # 基础分数

# 可选字段
requirements:          # 前置挑战（名称列表）
  - "前置挑战名称"
state: visible         # visible/hidden
hints:                 # 提示列表
  - cost: 10           # 扣分
    text: "第一个提示"
  - cost: 20
    text: "更详细的提示"
tags:                  # 标签
  - xss
  - beginner
```

## 4. 难度分级标准

| 难度   | 分数范围 | 预期解题率 | 技术要求                         |
| ------ | -------- | ---------- | -------------------------------- |
| Easy   | 50-150   | >60%       | 基础知识，单一漏洞点             |
| Medium | 150-300  | 30-60%     | 组合利用，需要一定脚本能力       |
| Hard   | 300-400  | 10-30%     | 深度分析，自定义 exploit         |
| Insane | 400-500  | <10%       | 0day级别，多阶段利用链           |

## 5. Docker 安全部署规范

### 5.1 容器安全
```dockerfile
# ✅ 推荐做法
FROM python:3.12-slim
RUN useradd -m -s /bin/bash challenger
USER challenger                    # 非 root 运行
WORKDIR /home/challenger/app

# ❌ 禁止做法
# USER root
# RUN apt-get install netcat       # 除非必要，不要安装额外网络工具
```

### 5.2 资源限制
```yaml
# docker-compose.yml
services:
  challenge:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
    # 安全选项
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp:size=64M
```

### 5.3 网络隔离
```yaml
networks:
  challenge-net:
    driver: bridge
    internal: true        # 禁止访问外网
    ipam:
      config:
        - subnet: 172.21.0.0/24
```

## 6. Flag 格式规范

```
标准格式: CTF{descriptive_content_here}

示例:
  ✅ CTF{sql_injection_basic_2024}
  ✅ CTF{rsa_wiener_attack_e=big_n}
  ❌ flag{xxx}
  ❌ CTF{abc123}
```

## 7. 质量审查清单

出题前检查：
- [ ] 题目描述清晰，目标明确
- [ ] 有至少一条免费提示
- [ ] Flag 已替换为实际值（非模板）
- [ ] Docker 容器可以正常启动和访问
- [ ] 非预期解法已检查
- [ ] 自动化验证脚本可正常运行
- [ ] 资源限制已设置（CPU/内存）
- [ ] 已配置正确的网络隔离级别
- [ ] Writeup 已完成（赛后发布用）

## 8. 出题禁止项

- ❌ 依赖外部网络服务（除非明确说明）
- ❌ 可能损坏服务器文件系统的操作
- ❌ 需要 root 权限的挑战
- ❌ 可能影响其他挑战的全局配置修改
- ❌ 涉及真实漏洞利用的恶意代码
- ❌ 需要猜测（无任何线索）的题
- ❌ 侵犯第三方知识产权的素材
