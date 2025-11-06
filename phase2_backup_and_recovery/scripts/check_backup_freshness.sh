#!/usr/bin/env bash
set -euo pipefail
BASE="/srv/backup"
FAIL=0
for H in web-node db-node log-node; do
  LAST="$(ls -1 ${BASE}/${H} 2>/dev/null | sort | tail -n1 || true)"
  if [[ -z "${LAST}" ]]; then
    echo "CRITICAL: no snapshots for ${H}"
    FAIL=1
    continue
  fi
  TS="$(date -d "${LAST//_/ }" +%s 2>/dev/null || echo 0)"
  NOW="$(date +%s)"
  if (( NOW - TS > 36*3600 )); then
    echo "WARNING: ${H} backup older than 36h: ${LAST}"
    FAIL=1
  else
    echo "OK: ${H} latest ${LAST}"
  fi
done
exit ${FAIL}
