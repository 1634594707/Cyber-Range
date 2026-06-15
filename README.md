# 🛡️ Cyber Range 网络安全靶场

> **香港 VPC · Debian 12 · 8C8G · 专业 CTF 竞技平台**

```ascii
  ▄████▄  ▓██   ██▓ ▄▄▄▄   ▓█████  ██▀███  
 ▒██▀ ▀█   ▒██  ██▒▓█████▄ ▓█   ▀ ▓██ ▒ ██▒
 ▒▓█    ▄   ▒██ ██░▒██▒ ▄██▒███   ▓██ ░▄█ ▒
 ▒▓▓▄ ▄██▒  ░ ▐██▓░▒██░█▀  ▒▓█  ▄ ▒██▀▀█▄  
 ▒ ▓███▀ ░  ░ ██▒▓░░▓█  ▀█▓░▒████▒░██▓ ▒██▒
 ░ ░▒ ▒  ░   ██▒▒▒ ░▒▓███▀▒░░ ▒░ ░░ ▒▓ ░▒▓░
   ░  ▒    ▓██ ░▒░ ▒░▒   ░  ░ ░  ░  ░▒ ░ ▒░
 ░         ▒ ▒ ░░   ░    ░    ░     ░░   ░ 
 ░ ░       ░ ░      ░         ░  ░   ░     
 ░         ░ ░           ░                  

        R A N G E   C Y B E R
```

## 📋 项目结构

```
Cyber Range/
├── README.md                          ← 你在这里
├── ARCHITECTURE.md                    ← 架构设计文档
├── deploy/                            ← 部署脚本
│   ├── server-setup.sh               # 一键部署（服务器上运行）
│   ├── docker-compose.yml            # 本地开发编排
│   ├── docker-compose.prod.yml       # 生产环境编排
│   ├── nginx/ctfd.conf               # Nginx 配置
│   └── env.example                   # 环境变量模板
├── challenges/                        ← 挑战题库（6 道入门题）
│   ├── web/                          # XSS | SQLi | SSRF | 文件上传
│   ├── crypto/                       # RSA 低指数攻击
│   ├── reverse/                      # XOR 加密破解
│   ├── forensics/                    # 网络流量分析
│   └── pwn/                          # 栈溢出 101
├── theme/                             ← Premium 前端主题
│   └── ctfd-theme-cyber/             # 赛博暗色主题
├── monitoring/                        ← 监控告警
├── security/                          ← 安全加固
│   ├── firewalld/nftables.conf       # 防火墙规则
│   ├── fail2ban/jail.local           # 入侵防护
│   └── audit/audit.sh               # 安全审计脚本
└── docs/                              ← 团队文档
    ├── ops-guide.md                  # 运维手册
    ├── challenge-dev-guide.md        # 出题规范
    └── team-skill-roadmap.md         # 团队技能路线图
```

## 🚀 快速开始

### 1. 服务器部署（5 分钟）

```bash
# SSH 登录你的香港服务器
ssh root@YOUR_SERVER_IP

# 上传部署脚本
scp deploy/server-setup.sh root@YOUR_SERVER_IP:/root/

# 设置域名（修改后运行）
export DOMAIN="ctf.your-company.com"
export ADMIN_EMAIL="admin@your-company.com"

# 一键部署
chmod +x server-setup.sh
sudo ./server-setup.sh
```

### 2. 本地开发

```bash
# 启动开发环境
cd deploy
docker compose up -d

# 访问 http://localhost:8000
# 首次访问完成 CTFd 初始化设置
```

### 3. 导入挑战题目

1. 登录 CTFd 管理后台 → Admin Panel
2. Challenges → Add Challenge
3. 选择 Standard 类型
4. 复制 `challenges/` 目录下的题目描述
5. 设置分数、提示、Flag
6. 配置 Docker 容器（如有）

### 4. 应用 Premium 主题

```bash
# 将主题复制到 CTFd themes 目录
cp -r theme/ctfd-theme-cyber/ /mnt/data/ctfd/themes/

# 或者通过 Admin Panel → Config → Theme 切换
```

## 📊 平台能力

| 能力           | 说明                              |
| -------------- | --------------------------------- |
| CTF 竞赛       | Jeopardy 模式，支持团队/个人      |
| Docker 隔离    | 挑战容器自动部署、网络隔离        |
| 计分系统       | 动态计分、实时排行榜              |
| 6 类基础挑战   | Web / Crypto / Reverse / PWN / Forensics / Misc |
| Premium UI     | 赛博暗色主题、玻璃拟态、流畅动画  |
| 安全加固       | SSH/Firewall/Fail2Ban/审计        |
| 监控告警       | Prometheus + 自定义告警规则       |

## 🎮 预置挑战

| # | 题目               | 类别      | 难度   | 分数 |
|---|-------------------|----------|--------|------|
| 1 | XSS 反射型入门     | Web      | Easy   | 100  |
| 2 | SQLi Union 注入   | Web      | Medium | 200  |
| 3 | SSRF 内网探测      | Web      | Medium | 250  |
| 4 | 文件上传绕过       | Web      | Medium | 200  |
| 5 | XOR 加密破解       | Reverse  | Easy   | 150  |
| 6 | RSA 低指数攻击     | Crypto   | Easy   | 150  |
| 7 | 网络流量分析       | Forensics| Easy   | 150  |
| 8 | 栈溢出入门         | PWN      | Medium | 250  |

## 🔐 安全特性

- ✅ SSH 自定义端口 + 密钥认证
- ✅ nftables 防火墙（最小开放原则）
- ✅ Fail2Ban 自动封禁
- ✅ Nginx 限流 + WAF 基础规则
- ✅ SSL/TLS 1.3（Let's Encrypt 自动续期）
- ✅ 管理后台 IP 白名单
- ✅ Docker 容器资源限制
- ✅ 每日自动备份

## 📈 性能指标

- 页面加载 < 800ms（CDN 缓存）
- 支持 50-100 并发选手
- 同时 10-15 在线挑战容器
- 7×24 自动备份

## 🛠️ 运维命令速查

```bash
# 服务管理
docker compose -f /mnt/data/docker-compose.yml up -d    # 启动
docker compose -f /mnt/data/docker-compose.yml logs -f   # 日志

# 备份恢复
/usr/local/bin/ctfd-backup                                # 手动备份
ls /mnt/data/backups/                                     # 查看备份

# 安全审计
/usr/local/bin/ctfd-audit.sh                              # 执行审计
fail2ban-client status                                     # 封禁状态
```

## 👥 团队能力提升

参考 `docs/team-skill-roadmap.md` — 3 个月从基础到独立出题。

## ⚠️ 重要提示

1. **首次部署**: 修改 `deploy/server-setup.sh` 中 `DOMAIN` 和 `ADMIN_EMAIL` 变量
2. **密码安全**: 部署后立即保存 `/root/.ctfd-credentials` 中的凭据
3. **定期备份**: 备份文件位于 `/mnt/data/backups/`，建议同步到远程
4. **资源监控**: 8G 内存约支持 10-15 个并发 Docker 挑战容器

## 📝 License

内部使用 | Cyber Range Team
