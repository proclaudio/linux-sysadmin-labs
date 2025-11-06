# 🧠 Phase 1 – System Installation & Hardening  
**Linux System Administration Lab | Rocky Linux 8.10**

---

## 📘 Overview

This phase establishes a **secure and standardized base environment** across a 4-node Rocky Linux 8.10 cluster.  
It demonstrates how to install, configure, and harden enterprise-grade Linux systems in accordance with security best practices (CIS Benchmarks Level 1 + NIST guidelines).

The deliverables from this phase provide a foundation for all subsequent phases — ensuring each node is patched, hardened, and compliant before deploying additional services.

---

## 🖥️ Environment Architecture

| Node | IP Address | FQDN | Role | Purpose |
|------|-------------|------|------|----------|
| **admin-node** | 192.168.111.140 | admin-node.example.com | Control Node | Central administration, backups, orchestration |
| **web-node** | 192.168.111.141 | web-node.example.com | Web Server | Nginx/Apache front-end workloads |
| **db-node** | 192.168.111.142 | db-node.example.com | Database Server | MariaDB/PostgreSQL back-end data services |
| **log-node** | 192.168.111.143 | log-node.example.com | Logging / Monitoring | rsyslog, Prometheus, Grafana, central logs |

**OS Version:** Rocky Linux 8.10 (Blue Onyx)  
**Kernel:** 4.18.0-553.80.1.el8_10.x86_64  
**Primary User:** `sysadmin` (/home/sysadmin, sudo-enabled)

---

## ⚙️ Objectives

1. Perform full system updates and baseline package installation.  
2. Enforce secure SSH configuration (no root login, public key authentication).  
3. Implement password complexity and expiration policies.  
4. Enable and verify SELinux in enforcing mode.  
5. Configure firewalld rules per node role.  
6. Generate compliance reports and verification outputs.  
7. Document all steps and results for GitHub proof-of-work.

---

## 🔐 Security Hardening Standards Implemented

| Category | Configuration | Validation |
|-----------|---------------|-------------|
| **System Updates** | Applied `dnf update -y` on all nodes | Verified no pending updates |
| **SSH Security** | `PermitRootLogin no`, `PubkeyAuthentication yes`, `MaxAuthTries 4` | Confirmed via `sshd_config` snapshot |
| **Password Policy** | `/etc/security/pwquality.conf` → `minlen=12`, credit settings ≥ 1 for each class | Verified using `grep minlen` |
| **User Access** | `sysadmin` user added to wheel group, password expires in 90 days | Validated with `id` and `chage` |
| **SELinux** | Enforcing mode, policy = targeted | Confirmed via `getenforce` |
| **Firewall** | firewalld active with role-specific zones | Verified via `firewall-cmd --list-all` |
| **Audit Proofs** | Generated hardening reports and verification logs | Uploaded to GitHub for traceability |

---

## 🧰 Tools & Scripts

| Script | Purpose |
|---------|----------|
| **hardening_run.sh** | Automates system updates, SSH configuration, password policy, SELinux enforcement, and firewall setup. Generates `hardening_report_<node>.txt`. |
| **verify_hardening.sh** | Performs compliance verification for all major security baselines (SSH, SELinux, password policy, firewall). Produces `hardening_verify_<node>.txt`. |

---

## 📄 Generated Reports

Each node produced the following documentation artifacts:

| File | Description |
|------|--------------|
| `hardening_report_admin-node.txt` | Baseline system configuration snapshot for the control node |
| `hardening_report_web-node.txt` | Web server hardening summary |
| `hardening_report_db-node.txt` | Database node hardening verification |
| `hardening_report_log-node.txt` | Logging/monitoring node configuration snapshot |
| `hardening_verify_<node>.txt` | Automated compliance check results |

All reports are stored under `phase1_system_install_hardening/` and version-controlled in GitHub for auditability.

---

## 🧩 Highlights

- ✅ Performed OS updates and installed baseline packages  
- ✅ Hardened SSH (removed root login, enforced key auth)  
- ✅ Applied password complexity (minlen = 12, mixed case required)  
- ✅ Enabled SELinux in enforcing mode  
- ✅ Configured role-based firewall rules  
- ✅ Generated per-node hardening and verification reports  
- ✅ Structured results for GitHub proof-of-work  

---

## 🧠 Verification & Validation

To confirm compliance on any node, run:

```bash
sudo ./verify_hardening.sh

**Expected Output:
✅ All checks passed!

🏁 Outcome

All four nodes successfully passed system hardening verification.
This phase establishes a secure baseline for subsequent automation, backup, and monitoring projects.
