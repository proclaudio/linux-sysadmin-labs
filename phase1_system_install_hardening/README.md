# Phase 1 – Project 1: System Installation & Hardening

## Environment
- **OS:** Rocky Linux 8.10 (Blue Onyx)
- **Kernel:** 4.18.0-553.80.1.el8_10.x86_64
- **User:** sysadmin (/home/sysadmin)

| Node | IP | Role |
|------|----|------|
| 192.168.111.140 | admin-node | Control Node |
| 192.168.111.141 | web-node | Web Server |
| 192.168.111.142 | db-node | Database Server |
| 192.168.111.143 | log-node | Logging/Monitoring |

## Highlights
- System updates and baseline packages installed  
- SSH hardened (no root login, enforced pubkey auth)  
- SELinux set to Enforcing  
- Firewalld configured per role  
- Password complexity policy (minlen=12)  
- Reports generated for compliance proof  

## Verification
Run:
```bash
sudo ./verify_hardening.sh

