# 🛡️ Cyber Range 运维手册

## 1. 服务器信息速查

| 项目       | 信息                      |
| ---------- | ------------------------- |
| IP/域名    | `your-domain.com`         |
| SSH        | `ssh -p 22022 user@host`  |
| 平台地址   | `https://your-domain.com` |
| 数据目录   | `/mnt/data/`              |
| 备份目录   | `/mnt/data/backups/`      |

## 2. 常用运维命令

### 2.1 服务管理
```bash
# 启动所有服务
docker compose -f /mnt/data/docker-compose.yml up -d

# 停止所有服务
docker compose -f /mnt/data/docker-compose.yml down

# 重启 CTFd
docker compose -f /mnt/data/docker-compose.yml restart ctfd

# 查看日志
docker compose -f /mnt/data/docker-compose.yml logs -f --tail=100 ctfd

# 查看所有容器状态
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 2.2 数据库操作
```bash
# 进入 PostgreSQL
docker exec -it cr-postgres psql -U ctfd

# 手动备份
/usr/local/bin/ctfd-backup

# 恢复数据库
docker exec -i cr-postgres psql -U ctfd ctfd < backup.sql
```

### 2.3 系统监控
```bash
# 资源使用
htop                      # CPU/内存
df -h                     # 磁盘
docker stats --no-stream  # 容器资源

# 网络连接
ss -tlnp                  # 监听端口
iftop                     # 实时流量（需安装）
```

## 3. 日常巡检清单

### 每日检查
- [ ] 平台可访问性：访问首页确认正常
- [ ] 容器状态：`docker ps` 确认所有容器 running
- [ ] 磁盘空间：`df -h` 确保 > 20% 可用
- [ ] 备份状态：确认 `/mnt/data/backups/` 有最新备份

### 每周检查
- [ ] 系统更新：`apt update && apt list --upgradable`
- [ ] 日志审查：检查 `/var/log/nginx/ctfd_error.log`
- [ ] Fail2Ban 状态：`fail2ban-client status`
- [ ] SSL 证书有效期：`certbot certificates`

### 每月检查
- [ ] 安全审计：`lynis audit system`
- [ ] Docker 镜像清理：`docker system prune -a`
- [ ] 备份恢复测试：模拟数据库恢复
- [ ] 性能基线对比：与历史数据对比

## 4. 故障处理

### 4.1 CTFd 无法访问
```bash
# 1. 检查容器
docker ps | grep ctfd

# 2. 检查日志
docker logs cr-ctfd --tail=50

# 3. 重启服务
docker compose -f /mnt/data/docker-compose.yml restart ctfd

# 4. 检查数据库连接
docker exec cr-ctfd python -c "from CTFd import create_app; app=create_app()"
```

### 4.2 数据库连接失败
```bash
# 检查 PostgreSQL
docker logs cr-postgres --tail=30
docker exec cr-postgres pg_isready -U ctfd
```

### 4.3 磁盘空间不足
```bash
# 清理 Docker
docker system prune -a -f

# 清理旧日志
journalctl --vacuum-time=7d
find /var/log -name "*.log.*" -mtime +30 -delete

# 检查大文件
du -sh /mnt/data/* | sort -h
```

## 5. 扩容指南

### 5.1 磁盘扩容
1. 云控制台扩展数据盘
2. `growpart /dev/vdb 1`
3. `resize2fs /dev/vdb1`

### 5.2 性能优化
```bash
# CTFd worker 调整（/mnt/data/docker-compose.yml）
# 公式: WORKERS = (2 * CPU核心数) + 1
environment:
  WORKERS: "5"  # 8核: (2*8)+1=17, 但内存有限，建议5
```

## 6. 应急预案

### 场景A: 被攻击/入侵
1. 立即执行 `docker compose down` 停止服务
2. 通过云控制台隔离服务器
3. 检查 `/var/log/auth.log` 确认入侵路径
4. 从最新备份恢复
5. 修复漏洞后重新上线

### 场景B: 数据丢失
```bash
# 列出可用备份
ls -la /mnt/data/backups/

# 恢复数据库
gunzip -c /mnt/data/backups/ctfd_db_20240615_020000.sql.gz | \
  docker exec -i cr-postgres psql -U ctfd ctfd

# 恢复上传文件
tar -xzf /mnt/data/backups/ctfd_uploads_20240615_020000.tar.gz -C /mnt/data/ctfd/
```
