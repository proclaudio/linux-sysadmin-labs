#!/usr/bin/env bash
set -euo pipefail
ADM="backup@admin-node.example.com"
REMOTE_BASE="/srv/backup"
HOST="$(hostname -s)"
DATE="$(date +%F_%H%M)"
SNAP_DIR="${HOST}/${DATE}"
INCLUDE_FILE="/etc/backup/include.list"
EXCLUDE_FILE="/etc/backup/exclude.list"
LOG_DIR="/var/log/backup"
LOG_FILE="${LOG_DIR}/backup_${DATE}.log"
RETENTION_DAYS=14
mkdir -p "${LOG_DIR}"
{
  echo "==== Backup start: $(date -Is) ===="
  echo "Host: ${HOST}  Snapshot: ${SNAP_DIR}"
  [[ -f "${INCLUDE_FILE}" ]] || { echo "Missing ${INCLUDE_FILE}"; exit 1; }
  [[ -f "${EXCLUDE_FILE}" ]] || { echo "Missing ${EXCLUDE_FILE}"; exit 1; }
  LAST_SNAP="$(ssh -o BatchMode=yes ${ADM} "ls -1 ${REMOTE_BASE}/${HOST} 2>/dev/null | sort | tail -n1" || true)"
  LINKDEST_ARG=""
  [[ -n "${LAST_SNAP}" ]] && LINKDEST_ARG="--link-dest=${REMOTE_BASE}/${HOST}/${LAST_SNAP}"
  TARGET="${ADM}:${REMOTE_BASE}/${SNAP_DIR}"
  rsync -aAXH --numeric-ids --delete --delete-excluded \
    --human-readable --info=stats2,progress2 --compress \
    --files-from="${INCLUDE_FILE}" --exclude-from="${EXCLUDE_FILE}" \
    ${LINKDEST_ARG} / "${TARGET}"
  ssh ${ADM} "cd ${REMOTE_BASE}/${SNAP_DIR} && find . -type f -print0 | xargs -0 sha256sum > MANIFEST.sha256"
  ssh ${ADM} "find ${REMOTE_BASE}/${HOST} -maxdepth 1 -type d -name '20*' -mtime +${RETENTION_DAYS} -exec rm -rf {} +"
  echo "==== Backup end: $(date -Is) ===="
} | tee -a "${LOG_FILE}"
