#!/bin/bash
# ============================================================
# 🛡️ Cyber Range — Debian 12 服务器一键部署脚本
# 用途: 初始化香港 VPC 服务器，部署完整网络安全靶场
# 运行: chmod +x server-setup.sh && sudo ./server-setup.sh
# ============================================================
set -euo pipefail

# ---- 颜色输出 ----
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; exit 1; }
step()  { echo -e "\n${CYAN}▶ $*${NC}"; }

# ---- 检查 root ----
[[ $EUID -eq 0 ]] || error "请使用 sudo 运行此脚本"

# ---- 配置变量 ----
DOMAIN="${DOMAIN:-ctf.example.com}"           # 修改为你的域名
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
SSH_PORT="${SSH_PORT:-22022}"
CTFD_VERSION="3.7.5"
DATA_DIR="/mnt/data"
POSTGRES_PASSWORD=$(openssl rand -base64 24)
REDIS_PASSWORD=$(openssl rand -base64 18)
CTFD_SECRET=$(openssl rand -base64 32)

# ============================================================
# STEP 1: 系统更新与基础配置
# ============================================================
step "系统更新与基础配置"
apt-get update -qq && apt-get upgrade -y -qq
apt-get install -y -qq \
    curl wget git vim htop net-tools \
    ca-certificates gnupg lsb-release \
    ufw nftables fail2ban \
    unattended-upgrades apt-listchanges \
    software-properties-common

# 时区设置
timedatectl set-timezone Asia/Hong_Kong
info "系统更新完成 | 时区: Asia/Hong_Kong"

# ============================================================
# STEP 2: 数据盘挂载
# ============================================================
step "挂载数据盘 (50GB)"
if ! mountpoint -q "$DATA_DIR" 2>/dev/null; then
    DATA_DISK=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT -n | \
        awk '$2=="50G" && $3=="disk" && $4=="" {print "/dev/"$1; exit}')
    
    if [[ -n "$DATA_DISK" ]]; then
        mkfs.ext4 -F "$DATA_DISK" 2>/dev/null || true
        mkdir -p "$DATA_DIR"
        mount "$DATA_DISK" "$DATA_DIR"
        echo "$DATA_DISK $DATA_DIR ext4 defaults 0 2" >> /etc/fstab
        info "数据盘挂载成功: $DATA_DISK → $DATA_DIR"
    else
        warn "未检测到独立数据盘，使用系统盘"
        mkdir -p "$DATA_DIR"
    fi
else
    info "数据盘已挂载"
fi

# ============================================================
# STEP 3: Docker 安装
# ============================================================
step "安装 Docker Engine"
if ! command -v docker &>/dev/null; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
    info "Docker $(docker --version | cut -d' ' -f3 | tr -d ',') 安装完成"
else
    info "Docker 已安装: $(docker --version)"
fi

# Docker 数据目录指向数据盘
mkdir -p "$DATA_DIR/docker"
cat > /etc/docker/daemon.json << 'DOCKEREOF'
{
  "data-root": "/mnt/data/docker",
  "log-driver": "json-file",
  "log-opts": { "max-size": "50m", "max-file": "3" },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "nofile": { "Name": "nofile", "Hard": 64000, "Soft": 64000 }
  }
}
DOCKEREOF
systemctl restart docker
info "Docker 数据目录: $DATA_DIR/docker"

# ============================================================
# STEP 4: 数据目录创建
# ============================================================
step "创建数据持久化目录"
mkdir -p "$DATA_DIR"/{postgresql,redis,ctfd/{uploads,logs},challenges,backups}
chown -R 1000:1000 "$DATA_DIR/ctfd/uploads"
info "数据目录创建完成"

# ============================================================
# STEP 5: Docker Compose 编排文件
# ============================================================
step "生成 Docker Compose 编排文件"
cat > "$DATA_DIR/docker-compose.yml" << COMPOSEEOF
version: "3.9"
services:
  # ---- PostgreSQL 16 ----
  postgres:
    image: postgres:16-alpine
    container_name: cr-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ctfd
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ctfd
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - /mnt/data/postgresql:/var/lib/postgresql/data
    networks:
      - ctfd-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ctfd"]
      interval: 10s; timeout: 5s; retries: 5

  # ---- Redis 7 ----
  redis:
    image: redis:7-alpine
    container_name: cr-redis
    restart: unless-stopped
    command: >
      redis-server --requirepass ${REDIS_PASSWORD}
      --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - /mnt/data/redis:/data
    networks:
      - ctfd-net
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s; timeout: 3s; retries: 5

  # ---- CTFd 平台 ----
  ctfd:
    image: ctfd/ctfd:${CTFD_VERSION}
    container_name: cr-ctfd
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
      redis: { condition: service_healthy }
    environment:
      DATABASE_URL: postgresql://ctfd:${POSTGRES_PASSWORD}@postgres:5432/ctfd
      REDIS_URL: redis://:${REDIS_PASSWORD}@redis:6379
      SECRET_KEY: ${CTFD_SECRET}
      REVERSE_PROXY: "1,2,4,6"
      UPLOAD_FOLDER: /var/uploads
      LOG_FOLDER: /var/log/CTFd
      WORKERS: "4"
    volumes:
      - /mnt/data/ctfd/uploads:/var/uploads
      - /mnt/data/ctfd/logs:/var/log/CTFd
      - /mnt/data/challenges:/var/challenges:ro
    networks:
      - ctfd-net
      - challenges-net
    ports:
      - "127.0.0.1:8000:8000"

  # ---- 可选: CTFd Docker 插件后端 ----
  ctfd-docker:
    image: ctfd/ctfd-docker:latest
    container_name: cr-ctfd-docker
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - challenges-net

networks:
  ctfd-net:
    driver: bridge
    ipam: { config: [{ subnet: 172.20.0.0/24 }] }
  challenges-net:
    driver: bridge
    ipam: { config: [{ subnet: 172.21.0.0/24 }] }
COMPOSEEOF
info "Docker Compose 编排文件已生成"

# ============================================================
# STEP 6: Nginx 安装与配置
# ============================================================
step "配置 Nginx 反向代理"
apt-get install -y -qq nginx certbot python3-certbot-nginx

cat > /etc/nginx/sites-available/ctfd << NGINXEOF
# ---- 限流区域 ----
limit_req_zone \$binary_remote_addr zone=login:10m rate=5r/m;
limit_req_zone \$binary_remote_addr zone=api:10m rate=30r/s;
limit_conn_zone \$binary_remote_addr zone=connlimit:10m;

# ---- 上游 ----
upstream ctfd_backend {
    server 127.0.0.1:8000 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

server {
    listen 80;
    server_name ${DOMAIN};
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # 限流
    limit_req zone=api burst=50 nodelay;
    limit_conn connlimit 30;
    
    # 日志
    access_log /var/log/nginx/ctfd_access.log;
    error_log /var/log/nginx/ctfd_error.log;
    
    # 静态资源缓存
    location /themes/ {
        proxy_pass http://ctfd_backend;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }
    
    location /files/ {
        proxy_pass http://ctfd_backend;
        expires 1h;
        add_header Cache-Control "public";
    }
    
    # 核心代理
    location / {
        proxy_pass http://ctfd_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
        
        # 大文件上传支持
        client_max_body_size 50M;
    }
    
    # 登录接口额外限流
    location /login {
        limit_req zone=login burst=3 nodelay;
        proxy_pass http://ctfd_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 禁用管理路径直接访问
    location ~ ^/(admin|setup) {
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;
        proxy_pass http://ctfd_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/ctfd /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
info "Nginx 配置完成"

# ============================================================
# STEP 7: SSL 证书 (Let's Encrypt)
# ============================================================
step "申请 SSL 证书"
if [[ "$DOMAIN" != "ctf.example.com" ]]; then
    certbot --nginx -d "$DOMAIN" \
        --non-interactive --agree-tos \
        -m "$ADMIN_EMAIL" \
        --redirect 2>/dev/null && \
        info "SSL 证书申请成功" || \
        warn "SSL 证书申请失败，请手动执行: certbot --nginx -d $DOMAIN"
else
    warn "使用默认域名，跳过 SSL 证书申请。请修改 DOMAIN 变量后重新运行。"
fi

# 自动续期 cron
echo "0 3 * * * root certbot renew --quiet --post-hook 'systemctl reload nginx'" \
    > /etc/cron.d/certbot-renew

# ============================================================
# STEP 8: 安全加固
# ============================================================
step "服务器安全加固"

# SSH 加固
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i "s/^#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveInterval.*/ClientAliveInterval 300/' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveCountMax.*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
systemctl restart sshd

# nftables 防火墙
cat > /etc/nftables.conf << NFTEOF
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        ct state established,related accept
        ct state invalid drop
        iif lo accept
        # SSH (管理端口)
        tcp dport ${SSH_PORT} accept
        # Web
        tcp dport {80, 443} accept
        # ICMP
        ip protocol icmp accept
        ip6 nexthdr ipv6-icmp accept
        # 日志丢弃
        log prefix "NFT-DROP: " limit rate 5/minute counter drop
    }
    chain forward { type filter hook forward priority 0; policy drop; }
    chain output { type filter hook output priority 0; policy accept; }
}
NFTEOF
systemctl enable nftables && systemctl restart nftables

# Fail2Ban
cat > /etc/fail2ban/jail.local << F2BEOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
banaction = nftables-multiport

[sshd]
enabled = true
port = ${SSH_PORT}
maxretry = 3

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
maxretry = 5
F2BEOF
systemctl restart fail2ban

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
info "安全加固完成 | SSH端口: $SSH_PORT"

# ============================================================
# STEP 9: 启动服务
# ============================================================
step "启动靶场平台"
cd "$DATA_DIR"
docker compose up -d
info "服务启动中..."

# 等待 CTFd 就绪
echo -n "等待 CTFd 就绪"
for i in $(seq 1 30); do
    if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000 2>/dev/null | grep -q "200\|302"; then
        echo ""
        info "CTFd 就绪!"
        break
    fi
    echo -n "."
    sleep 2
done

# ============================================================
# STEP 10: 自动备份脚本
# ============================================================
step "配置自动备份"
cat > /usr/local/bin/ctfd-backup << 'BACKUPEOF'
#!/bin/bash
BACKUP_DIR="/mnt/data/backups"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

# PostgreSQL 备份
docker exec cr-postgres pg_dump -U ctfd ctfd | gzip > "$BACKUP_DIR/ctfd_db_$DATE.sql.gz"

# 上传文件备份
tar -czf "$BACKUP_DIR/ctfd_uploads_$DATE.tar.gz" -C /mnt/data/ctfd uploads/

# 清理旧备份
find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete
echo "[$(date)] Backup completed: $DATE"
BACKUPEOF
chmod +x /usr/local/bin/ctfd-backup

# Cron: 每天凌晨 2 点备份
echo "0 2 * * * root /usr/local/bin/ctfd-backup >> /var/log/ctfd-backup.log 2>&1" \
    > /etc/cron.d/ctfd-backup
info "自动备份已配置（每日 02:00，保留 7 天）"

# ============================================================
# STEP 11: 输出部署信息
# ============================================================
step "部署完成! 🎉"
cat << SUMMARY

╔══════════════════════════════════════════════════════╗
║        🛡️ Cyber Range 部署完成                       ║
╠══════════════════════════════════════════════════════╣
║  平台地址:   https://${DOMAIN}          
║  CTFd 内部:  http://127.0.0.1:8000      
║  SSH 端口:   ${SSH_PORT}                            
║  数据目录:   ${DATA_DIR}                             
║  备份目录:   ${DATA_DIR}/backups                     
╠══════════════════════════════════════════════════════╣
║  数据库密码: ${POSTGRES_PASSWORD:0:16}...            
║  Redis 密码: ${REDIS_PASSWORD:0:12}...               
║  CTFd 密钥:  ${CTFD_SECRET:0:16}...                  
╠══════════════════════════════════════════════════════╣
║  启动: docker compose -f ${DATA_DIR}/docker-compose.yml up -d
║  停止: docker compose -f ${DATA_DIR}/docker-compose.yml down
║  日志: docker compose -f ${DATA_DIR}/docker-compose.yml logs -f ctfd
║  备份: /usr/local/bin/ctfd-backup
╚══════════════════════════════════════════════════════╝

⚠️  重要提醒:
  1. 首次访问 https://${DOMAIN} 完成 CTFd 初始化设置
  2. 创建管理员账户
  3. 在 Admin Panel → Settings 中配置 Docker 插件
  4. 修改 SSH 端口后，新连接请使用: ssh -p ${SSH_PORT} user@${DOMAIN}
  5. 妥善保管上述密码，建议存入密码管理器

SUMMARY

# 保存凭据文件
cat > /root/.ctfd-credentials << CREDEOF
CTFd Deployment Credentials ($(date))
======================================
Domain:        ${DOMAIN}
SSH Port:      ${SSH_PORT}
PG Password:   ${POSTGRES_PASSWORD}
Redis Pass:    ${REDIS_PASSWORD}
CTFd Secret:   ${CTFD_SECRET}
CREDEOF
chmod 600 /root/.ctfd-credentials
info "凭据已保存至 /root/.ctfd-credentials"

echo -e "\n${GREEN}部署脚本执行完毕! 🚀${NC}"
