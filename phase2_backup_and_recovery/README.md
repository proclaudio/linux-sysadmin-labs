# Phase 2 — Backup & Recovery (Full Implementation)

## 🌐 Architecture Overview

| Role           | Hostname                 | IP              | Purpose                                                         |
| -------------- | ------------------------ | --------------- | --------------------------------------------------------------- |
| **Admin Node** | `admin-node.example.com` | 192.168.111.140 | Central backup receiver, stores `/srv/backup/<node>/timestamp/` |
| **Web Node**   | `web-node.example.com`   | 192.168.111.141 | Hosts web/app data; pushes backups nightly                      |
| **DB Node**    | `db-node.example.com`    | 192.168.111.142 | Runs database dump, then pushes backups                         |
| **Log Node**   | `log-node.example.com`   | 192.168.111.143 | Centralized logs, pushes backups nightly                        |

### 🔁 Backup Flow

```
web-node ─┐
db-node  ─┼──► admin-node  (/srv/backup/<host>/<YYYY-MM-DD_HHMM>/)
log-node ─┘
```

* Backups are pushed via `rsync + SSH` using the `backup` user.
* Incremental snapshots (`--link-dest`) with 14-day retention.
* Integrity manifest (`MANIFEST.sha256`) per snapshot.
* db-node runs a database dump at 02:00 before rsync at 02:30.

---

## ⚙️ Admin Node Setup (Backup Receiver)

```bash
sudo useradd --create-home --shell /bin/bash backup
sudo mkdir -p /srv/backup/{web-node,db-node,log-node}
sudo chown -R backup:backup /srv/backup
sudo chmod -R 750 /srv/backup
sudo dnf install -y rsync coreutils policycoreutils-python-utils tree
sudo firewall-cmd --add-service=ssh --permanent && sudo firewall-cmd --reload
sudo semanage fcontext -a -t var_t "/srv/backup(/.*)?" && sudo restorecon -Rv /srv/backup
```

### Health Check Script

`/usr/local/sbin/check_backup_freshness.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
BASE="/srv/backup"
FAIL=0
for H in web-node db-node log-node; do
  LAST="$(ls -1 ${BASE}/${H} 2>/dev/null | sort | tail -n1 || true)"
  if [[ -z "${LAST}" ]]; then
    echo "CRITICAL: no snapshots for ${H}"
    FAIL=1; continue
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
```

(Optional) Daily timer at 09:00 writes to `/var/log/backup-monitor.log`.

---

## ⚙️ Source Node Setup (web, db, log)

### 1️⃣ SSH Key ( root → backup@admin-node )

```bash
sudo ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
sudo ssh-copy-id backup@admin-node.example.com
sudo ssh backup@admin-node.example.com 'hostname && echo OK'
```

### 2️⃣ Include / Exclude Lists

**web-node**

```
/etc
/var/www
/home
/var/log
```

**db-node**

```
/etc
/var/lib/mysql
/var/backups/db
/home
/var/log
```

**log-node**

```
/etc
/var/log
/home
```

Exclude list (same on all):

```
/proc
/sys
/dev
/run
/tmp
/var/tmp
/var/cache
```

### 3️⃣ Backup Script (`/usr/local/sbin/rsync_backup.sh`)

*(Identical on all source nodes)*

```bash
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
```

### 4️⃣ Systemd Units

`/etc/systemd/system/rsync-backup.service`

```ini
[Unit]
Description=Rsync push backup to admin-node
Wants=network-online.target
After=network-online.target
[Service]
Type=oneshot
User=root
ExecStart=/usr/local/sbin/rsync_backup.sh
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7
[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/rsync-backup.timer`

```ini
[Unit]
Description=Daily rsync backup to admin-node
[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true
RandomizedDelaySec=600
[Install]
WantedBy=timers.target
```

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now rsync-backup.timer
```

---

## 🗄️ Database Dump (db-node only)

`/usr/local/sbin/db_dump.sh`

```bash
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
```

Timer runs 02:00 daily (30 min before rsync):

```
/etc/systemd/system/db-dump.timer
/etc/systemd/system/db-dump.service
```

---

## ✅ Verification & Restore

**Admin-node**

```bash
sudo tree -L 2 /srv/backup
sudo /usr/local/sbin/check_backup_freshness.sh
```

Expected structure:

```
/srv/backup
├── web-node
│   └── 2025-11-06_1240
├── db-node
│   └── 2025-11-06_1245
└── log-node
    └── 2025-11-06_1250
```

**Integrity check**

```bash
cd /srv/backup/web-node/<timestamp>
sha256sum -c MANIFEST.sha256
```

**Restore example**

```bash
rsync -aAXH backup@admin-node.example.com:/srv/backup/web-node/<timestamp>/etc/myapp/ /etc/myapp/
```

---

## 🧹 Retention & Cleanup

* 14 days kept automatically (`RETENTION_DAYS=14`)
* Old snapshots removed during each run
* DB dumps kept in `/var/backups/db/` until rsynced and rotated

---

## 🧭 GitHub Deployment

```bash
cd ~/linux-sysadmin-labs
git add phase2_backup_and_recovery
git commit -m "Phase 2 — Backup & Recovery (full implementation)"
git push```

---

## 🏁 Phase 2 Results

* Automated, incremental backups for web, db, and log nodes
* Secure key-based SSH push to admin-node
* Database dumps integrated and timed
* Integrity and freshness verification
* Fully documented and version-controlled for Phase 3 progression

