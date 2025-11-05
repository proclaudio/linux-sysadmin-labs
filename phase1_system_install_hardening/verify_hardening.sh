#!/usr/bin/env bash
set -euo pipefail
FAILED=0

check() { eval "$1" >/dev/null 2>&1 || { echo "❌ $2"; FAILED=$((FAILED+1)); }; }

check "grep -q 'PermitRootLogin no' /etc/ssh/sshd_config" "SSH root login not disabled"
check "getenforce | grep -qi enforcing" "SELinux not enforcing"
check "systemctl is-active --quiet firewalld" "Firewalld inactive"
check "id sysadmin" "sysadmin user missing"
check "grep -q 'minlen = 12' /etc/security/pwquality.conf" "Weak password policy"

if [ "$FAILED" -eq 0 ]; then
  echo "✅ All checks passed!"
else
  echo "⚠️  $FAILED checks failed."
fi

