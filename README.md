# 🧠 Linux System Administration Lab Projects

## 📘 Overview
This repository contains a complete hands-on training roadmap for **Linux System Administration and Automation**, structured into multiple phases that progressively build enterprise-grade skills.

Each phase is fully documented, with scripts, configuration files, and proof-of-work reports designed to simulate real-world system administrator responsibilities — from system installation to backup automation, configuration management, and DevOps integration.

---

## 🧩 Project Roadmap

| Phase | Title | Focus Area | Key Skills |
|-------|--------|-------------|-------------|
| **1** | System Installation & Hardening | OS deployment, baseline security, SSH & SELinux configuration | System provisioning, hardening, audit |
| **2** | Backup & Recovery | rsync, cron, verification, centralized backup | Automation, recovery planning, disaster recovery |
| **3** | System Monitoring & Performance | (upcoming) Prometheus, Grafana, log aggregation | Monitoring, alerting, performance tuning |
| **4** | Automation & DevOps Integration | Ansible roles, GitHub Actions CI, OpenSCAP compliance | IaC, CI/CD, compliance, Ansible roles |

---

## 🧱 Environment Setup

| Node | IP Address | Role | Description |
|------|-------------|------|-------------|
| `admin-node` | 192.168.111.140 | Control / Central Node | Manages automation, backup repository, and Ansible orchestration |
| `web-node` | 192.168.111.141 | Web Server | Nginx / application server for testing deployments |
| `db-node` | 192.168.111.142 | Database Server | MariaDB or MySQL instance for testing DB admin tasks |
| `log-node` | 192.168.111.143 | Logging / Monitoring | Used for future monitoring, AIDE, and log aggregation setup |

**Base OS:** Rocky Linux 8.10 (Blue Onyx)  
**Kernel:** 4.18.0-553.80.1.el8_10.x86_64  
**User:** `sysadmin` (sudo-enabled)

---

## ⚙️ Tools and Technologies

| Category | Tools / Technologies |
|-----------|----------------------|
| **Operating System** | Rocky Linux 8 / RHEL 8 |
| **Automation & Config Management** | Ansible – role-based playbooks |
| **Version Control & CI/CD** | Git, GitHub Actions |
| **Backup & Recovery** | rsync, tar, cron, sha256sum |
| **Security & Compliance** | SELinux, OpenSCAP, Firewalld |
| **Monitoring (Planned)** | Prometheus, Grafana, AIDE |
| **Documentation** | Markdown, README, GitHub project structure |

---

## 🚀 Phase Summaries

### 🧩 **Phase 1 – System Installation & Hardening**
- Hardened SSH (disabled root, enforced key-auth)
- Configured SELinux enforcing mode
- Applied password policies (`pwquality.conf`)
- Firewalld and baseline package setup
- Automated verification script (`verify_hardening.sh`)

📁 Folder: `phase1_system_install_hardening/`

---

### 🧩 **Phase 2 – Backup & Recovery**
- Centralized rsync backup system with **admin-node** as central repository  
- Automated via cron (`/home/sysadmin/scripts/rsync_backup.sh`)  
- Compression + checksum verification  
- Restore simulation and integrity validation (`verify_backup.sh`)

📁 Folder: `phase2_backup_recovery/`

---

### 🧩 **Phase 3 – System Monitoring & Performance**
Planned deployment of:
- **Prometheus + Grafana** for live monitoring  
- **Node Exporter** for resource metrics  
- **Log rotation + alerting** integration  

📁 Folder: `phase3_monitoring_performance/`

---

### 🧩 **Phase 4 – Automation & DevOps Integration**
- Designed **Ansible roles**: `common`, `web`, `db`  
- Managed configurations via `site.yml` playbook  
- Implemented **GitHub Actions CI** for lint + syntax validation  
- Added **OpenSCAP compliance scanning** script  
- Optional GitLab CI template for on-prem runners

📁 Folder: `phase4_automation_devops/`

---

## 🧪 Testing and Validation
- ✅ All YAML validated with `yamllint` and `ansible-lint`  
- ✅ CI pipeline triggers automatically on each commit  
- ✅ Playbooks syntax-checked and dry-run validated (`--check`)  
- ✅ OpenSCAP reports included under `reports/openscap/`  

---

## 🔒 Security Highlights
- SSH hardened across all nodes  
- SELinux enforcing globally  
- Firewalld zone configuration per role  
- OpenSCAP compliance baseline for CIS/STIG profiles  
- Password policy enforcement & disabled unused services  

---

## 🧰 Repository Layout

linux-sysadmin-labs/
├── phase1_system_install_hardening/
├── phase2_backup_recovery/
├── phase3_monitoring_performance/ # (planned)
├── phase4_automation_devops/
│ ├── ansible.cfg
│ ├── inventory.ini
│ ├── site.yml
│ ├── roles/
│ │ ├── common/
│ │ ├── web/
│ │ └── db/
│ ├── scripts/
│ └── reports/
└── README.md


---

## 🧠 Learning Outcomes
By completing this lab series, you demonstrate:
- Real-world **Linux system administration** proficiency  
- Mastery of **automation and scripting** (Bash / Ansible)  
- CI/CD integration and **infrastructure-as-code** discipline  
- **Security & compliance** awareness using industry-standard tools  
- Portfolio-ready documentation and GitHub project hygiene  

---

## 📎 Author
**Project Maintainer:** sysadmin  
**Repository:** [github.com/proclaudio/linux-sysadmin-labs](https://github.com/proclaudio/linux-sysadmin-labs)

---

