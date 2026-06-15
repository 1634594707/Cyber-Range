#!/bin/bash
# ============================================================
# 🏴‍☠️ Cyber Range Lab — 红蓝实验室一键部署
# 功能: 部署 Kali + 靶场 + WAF + IDS + HIDS
# 内存预算: ~4.5G (红队2.5G + 蓝队2G)
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
info() { echo -e "${GREEN}[✓]${NC} $*"; }
step() { echo -e "\n${CYAN}▶ $*${NC}"; }
LAB_DIR="/mnt/data/lab"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[[ $EUID -eq 0 ]] || { echo "请用 sudo 运行"; exit 1; }

# ============================================================
# STEP 1: 创建目录结构
# ============================================================
step "创建实验室目录"
mkdir -p "$LAB_DIR"/{kali,shared,vulhub}
mkdir -p "$LAB_DIR/waf"/{logs,rules}
mkdir -p "$LAB_DIR/suricata"/{logs,rules,config}
mkdir -p "$LAB_DIR/ossec"/{data,logs,etc}
mkdir -p "$LAB_DIR/nids/logs"
mkdir -p "$LAB_DIR/traffic"
mkdir -p "$LAB_DIR/guides"
info "目录结构已创建"

# ============================================================
# STEP 2: 创建实验室 Docker 网络
# ============================================================
step "创建实验室隔离网络 (172.30.0.0/24)"
if ! docker network inspect lab-net &>/dev/null; then
    docker network create \
        --driver bridge \
        --subnet=172.30.0.0/24 \
        --ip-range=172.30.0.0/24 \
        lab-net
    info "lab-net 网络已创建"
else
    info "lab-net 网络已存在"
fi

# ============================================================
# STEP 3: 部署红队环境
# ============================================================
step "部署红队环境"

# 检查并选择要启动的靶场
echo ""
echo "  选靶场启动模式:"
echo "  1) 仅 Kali 攻击机 (1G 内存)"
echo "  2) Kali + DVWA (1.5G 内存)"
echo "  3) Kali + DVWA + Juice Shop (2G 内存)"
echo "  4) 全部启动 (2.5G 内存)"
read -p "  请选择 [1-4]: " MODE

cd "$SCRIPT_DIR/../red-team"

case $MODE in
    1)
        docker compose up -d kali
        info "Kali 攻击机已启动 → http://服务器IP:3001"
        ;;
    2)
        docker compose up -d kali dvwa
        info "Kali + DVWA 已启动"
        info "  Kali: http://服务器IP:3001"
        info "  DVWA: http://服务器IP:8081"
        ;;
    3)
        docker compose up -d kali dvwa juice-shop
        info "Kali + DVWA + Juice Shop 已启动"
        info "  Kali:       http://服务器IP:3001"
        info "  DVWA:       http://服务器IP:8081"
        info "  Juice Shop: http://服务器IP:3000"
        ;;
    4)
        docker compose up -d
        info "全红队环境已启动"
        info "  Kali:        http://服务器IP:3001"
        info "  DVWA:        http://服务器IP:8081"
        info "  Juice Shop:  http://服务器IP:3000"
        info "  WebGoat:     http://服务器IP:8082"
        info "  Metasploit:  SSH root@172.30.0.30 (pass: root)"
        ;;
    *)
        docker compose up -d kali
        info "默认模式: 仅 Kali 攻击机"
        ;;
esac

# ============================================================
# STEP 4: 部署蓝队环境 (可选)
# ============================================================
step "蓝队防御环境"
read -p "  是否部署蓝队防御环境 (ModSecurity + Suricata + OSSEC, 约2G)? [y/N]: " BLUE

if [[ "$BLUE" =~ ^[Yy]$ ]]; then
    cd "$SCRIPT_DIR/../blue-team"

    # 创建 Suricata 配置
    if [ ! -f "$LAB_DIR/suricata/config/suricata.yaml" ]; then
        cat > "$LAB_DIR/suricata/config/suricata.yaml" << 'SURYAML'
%YAML 1.1
---
vars:
  address-groups:
    HOME_NET: "[172.30.0.0/24,10.0.0.0/8,192.168.0.0/16]"
    EXTERNAL_NET: "!$HOME_NET"
    HTTP_SERVERS: "$HOME_NET"
    SMTP_SERVERS: "$HOME_NET"
    SQL_SERVERS: "$HOME_NET"
    DNS_SERVERS: "$HOME_NET"
    TELNET_SERVERS: "$HOME_NET"

default-rule-path: /var/lib/suricata/rules
rule-files:
  - emerging-attack_response.rules
  - emerging-current_events.rules
  - emerging-malware.rules
  - emerging-scan.rules
  - emerging-shellcode.rules
  - emerging-web_server.rules
  - emerging-web_specific_apps.rules

af-packet:
  - interface: eth0
    cluster-id: 99
    cluster-type: cluster_flow
    defrag: yes

outputs:
  - fast:
      enabled: yes
      filename: fast.log
      append: yes
  - eve-log:
      enabled: yes
      filetype: regular
      filename: eve.json
      types:
        - alert
        - http
        - dns
        - tls
        - ssh
        - flow

detect-engine:
  - profile: medium
  - custom-values:
      toclient-groups: 2
      toserver-groups: 25
SURYAML
        info "Suricata 配置已创建"
    fi

    docker compose up -d
    info "蓝队环境已部署"
    info "  WAF (ModSecurity): http://服务器IP:8080 → 代理到 DVWA"
    info "  Suricata IDS: 监控 lab-net 流量"
    info "  OSSEC HIDS: 主机入侵检测"
else
    info "跳过蓝队部署"
fi

# ============================================================
# STEP 5: 配置 Nginx 代理 (使外部可访问)
# ============================================================
step "配置 Nginx 反向代理"

if ! grep -q "lab/" /etc/nginx/sites-enabled/ctfd 2>/dev/null; then
    cat > /etc/nginx/conf.d/lab.conf << 'NGXLAB'
# Kali 攻击机 Web 桌面
server {
    listen 80;
    server_name kali.18257.xyz;

    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 600s;
    }
}

# 靶场入口
server {
    listen 80;
    server_name lab.18257.xyz;

    location /dvwa {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
    }

    location /juice-shop {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
    }

    location /webgoat {
        proxy_pass http://127.0.0.1:8082;
        proxy_set_header Host $host;
    }

    location /waf {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
    }

    location / {
        return 200 "<html><body><h1>Cyber Range Lab</h1><ul>
            <li><a href='/dvwa'>DVWA</a></li>
            <li><a href='/juice-shop'>Juice Shop</a></li>
            <li><a href='/webgoat/WebGoat'>WebGoat</a></li>
            <li><a href='/waf'>WAF 实验 (代理到 DVWA)</a></li>
            </ul></body></html>";
    }
}
NGXLAB

    nginx -t && systemctl reload nginx
    info "Nginx 已配置。请添加 DNS 子域名记录:"
    info "  kali.18257.xyz → A → 服务器IP"
    info "  lab.18257.xyz  → A → 服务器IP"
else
    info "Nginx 代理已存在"
fi

# ============================================================
# STEP 6: 状态总览
# ============================================================
step "部署完成！🎉"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║     🏴‍☠️ Cyber Range 红蓝实验室已就绪                      ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  【红队 — 攻击环境】                                    ║"
echo "║  Kali 攻击机:    http://localhost:3001                 ║"
echo "║                  (或 http://kali.18257.xyz)            ║"
echo "║  DVWA 靶场:      http://localhost:8081                 ║"
echo "║  Juice Shop:     http://localhost:3000                 ║"
echo "║  WebGoat:        http://localhost:8082/WebGoat         ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  【蓝队 — 防御环境】(如已选择)                           ║"
echo "║  ModSecurity WAF: http://localhost:8080                ║"
echo "║  Suricata 日志:   /mnt/data/lab/suricata/logs/        ║"
echo "║  OSSEC 日志:      /mnt/data/lab/ossec/logs/           ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  学习指南:        /root/cyber-range/lab/guides/        ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  ⚠️ 重要合规提醒:"
echo "  所有操作仅限在自有服务器内进行！"
echo "  严禁对外部非授权系统发起任何攻击行为！"
echo ""
