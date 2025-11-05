#!/usr/bin/env bash
set -euo pipefail
HOSTNAME="${1:-$(hostname | tr -d '[:space:]')}"
ROLE="${2:-generic}"

echo "[*] Hardening ${HOSTNAME} (Role: ${ROLE}) on Rocky Linux 8.10..."

# System update
sudo dnf -y update
sudo dnf -y install vim git curl wget net-tools bind-utils lsof tree htop bash-completion unzip tar rsync policycoreutils-python-utils firewalld

# SSH hardening
SSHD_CONF="/etc/ssh/sshd_config"
sudo cp -p "$SSHD_CONF" "${SSHD_CONF}.bak.$(date +%F_%T)"
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONF"
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONF"
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONF"
sudo grep -q '^MaxAuthTries' "$SSHD_CONF" || echo 'MaxAuthTries 4' | sudo tee -a "$SSHD_CONF" >/dev/null
sudo systemctl restart sshd

# Password policy
sudo cp -p /etc/security/pwquality.conf /etc/security/pwquality.conf.bak.$(date +%F_%T)
sudo tee -a /etc/security/pwquality.conf <<'CFG'
minlen = 12
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
CFG
sudo chage --maxdays 90 --mindays 0 --warndays 7 sysadmin

# SELinux enforcing
sudo setenforce 1 || true
sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# Firewall setup
sudo systemctl enable --now firewalld
if [ "$ROLE" = "web" ]; then
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --permanent --add-service=https
elif [ "$ROLE" = "db" ]; then
  sudo firewall-cmd --permanent --add-port=3306/tcp
elif [ "$ROLE" = "log" ]; then
  sudo firewall-cmd --permanent --add-port=514/tcp
  sudo firewall-cmd --permanent --add-port=9090/tcp
  sudo firewall-cmd --permanent --add-port=3000/tcp
else
  sudo firewall-cmd --permanent --add-service=ssh
fi
sudo firewall-cmd --reload

# Report
REPORT="/home/sysadmin/hardening_report_${HOSTNAME}.txt"
{
  echo "===== HARDENING REPORT FOR ${HOSTNAME} ====="
  echo "Generated: $(date)"
  echo ""
  echo "Hostname: $(hostname)"
  echo "Role: ${ROLE}"
  echo "OS: Rocky Linux 8.10 (Blue Onyx)"
  echo "Kernel: 4.18.0-553.80.1.el8_10.x86_64"
  echo ""
  echo "[SSH CONFIG]"
  grep -E "^(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|MaxAuthTries)" /etc/ssh/sshd_config
  echo ""
  echo "[SELINUX STATUS]"
  getenforce
  echo ""
  echo "[FIREWALL STATUS]"
  sudo firewall-cmd --list-all
  echo ""
  echo "[PASSWORD POLICY]"
  grep -E "minlen|credit" /etc/security/pwquality.conf
} > "$REPORT"

echo "[+] Hardening completed successfully. Report: $REPORT"

