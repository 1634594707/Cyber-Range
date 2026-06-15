#!/bin/bash
# ============================================================
# 🛡️ Cyber Range — 安全审计脚本
# 用途: 定期执行服务器安全基线检查
# Cron: 0 4 * * 0 root /usr/local/bin/ctfd-audit.sh
# ============================================================

REPORT="/mnt/data/audit/audit-$(date +%Y%m%d).log"
mkdir -p /mnt/data/audit

echo "=== Cyber Range 安全审计 $(date) ===" | tee "$REPORT"
echo "" | tee -a "$REPORT"

# ---- 1. 检查 SSH 配置 ----
echo "[1/8] SSH 配置检查" | tee -a "$REPORT"
grep -E '^(Port|PermitRootLogin|PasswordAuthentication|MaxAuthTries)' /etc/ssh/sshd_config | tee -a "$REPORT"

# ---- 2. 检查防火墙状态 ----
echo "[2/8] 防火墙状态" | tee -a "$REPORT"
nft list ruleset 2>/dev/null | head -30 | tee -a "$REPORT"

# ---- 3. 检查 Fail2Ban ----
echo "[3/8] Fail2Ban 封禁记录" | tee -a "$REPORT"
fail2ban-client status sshd 2>/dev/null | tee -a "$REPORT"

# ---- 4. 检查监听端口 ----
echo "[4/8] 开放端口" | tee -a "$REPORT"
ss -tlnp | grep -v '127.0.0.1' | tee -a "$REPORT"

# ---- 5. 检查容器安全 ----
echo "[5/8] Docker 容器状态" | tee -a "$REPORT"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tee -a "$REPORT"
echo "" | tee -a "$REPORT"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | tee -a "$REPORT"

# ---- 6. 检查磁盘空间 ----
echo "[6/8] 磁盘使用" | tee -a "$REPORT"
df -h /mnt/data | tee -a "$REPORT"

# ---- 7. 检查最近登录 ----
echo "[7/8] 最近 SSH 登录" | tee -a "$REPORT"
last -n 10 2>/dev/null | tee -a "$REPORT"

# ---- 8. 检查未授权用户 ----
echo "[8/8] 特权用户检查" | tee -a "$REPORT"
awk -F: '($3 == 0) { print $1 }' /etc/passwd | tee -a "$REPORT"

echo "" | tee -a "$REPORT"
echo "=== 审计完成 ===" | tee -a "$REPORT"

# 保留最近 10 份报告
find /mnt/data/audit -name "audit-*.log" -mtime +70 -delete
