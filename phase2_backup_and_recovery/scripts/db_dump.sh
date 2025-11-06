#!/usr/bin/env bash
set -euo pipefail
DATE="$(date +%F_%H%M)"
OUT="/var/backups/db/mysql_${DATE}.sql.gz"
SOCK="/var/lib/mysql/mysql.sock"
if [[ ! -S "${SOCK}" ]]; then
  echo "[$(date -Is)] DB socket not found — skipping dump." | tee -a /var/log/db_dump.log
  exit 0
fi
mysqldump --all-databases --single-transaction --routines --events | gzip -c > "${OUT}"
chmod 600 "${OUT}"
