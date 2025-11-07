## 📘 **Phase 3 — System Monitoring & Alerting (Full Implementation)**

### 🧭 Objective
Deploy and configure a complete **monitoring and alerting stack** across all environment nodes using:  
- **Prometheus** for metric collection and rule-based alerts  
- **Alertmanager** for notifications through the internal Postfix relay  
- **Grafana** for visualization and dashboards  

---

### 🖥️ Environment Overview

| Role | Hostname | IP Address | Description |
|------|-----------|-------------|--------------|
| Admin Node | admin-node.example.com | 192.168.111.140 | Central management & Postfix mail relay |
| Web Node | web-node.example.com | 192.168.111.141 | Application / Web server |
| DB Node | db-node.example.com | 192.168.111.142 | Database server |
| Log Node | log-node.example.com | 192.168.111.143 | Monitoring hub (Prometheus + Alertmanager + Grafana) |

---

### ⚙️ Implementation Steps

#### **Step 1 — Install Node Exporter (on all nodes)**

NODE_EXPORTER_VER=1.8.2
cd /opt
sudo useradd --no-create-home --shell /usr/sbin/nologin nodeexp || true
curl -L -o node_exporter.tar.gz \
 https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VER}/node_exporter-${NODE_EXPORTER_VER}.linux-amd64.tar.gz
tar -xzf node_exporter.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VER}.linux-amd64/node_exporter /usr/local/bin/
sudo chown nodeexp:nodeexp /usr/local/bin/node_exporter
```

Create service file `/etc/systemd/system/node_exporter.service` and enable it.

---

#### **Step 2 — Prometheus Setup (on log-node)**

Install Prometheus:

PROM_VER=2.55.1
cd /opt
sudo useradd --no-create-home --shell /usr/sologin prometheus || true
sudo mkdir -p /etc/prometheus/{rules,conf.d} /var/lib/prometheus
curl -L -o prometheus.tar.gz \
 https://github.com/prometheus/prometheus/releases/download/v${PROM_VER}/prometheus-${PROM_VER}.linux-amd64.tar.gz
tar -xzf prometheus.tar.gz
sudo mv prometheus-${PROM_VER}.linux-amd64/{prometheus,promtool} /usr/local/bin/
sudo mv prometheus-${PROM_VER}.linux-amd64/{consoles,console_libraries} /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```

Create `/etc/prometheus/prometheus.yml` with all 4 nodes and configure `/etc/systemd/system/prometheus.service`.

Start and verify Prometheus at:  
👉 http://log-node:9090/targets

---

#### **Step 3 — Alertmanager (on log-node)**

Install Alertmanager and create `/etc/alertmanager/alertmanager.yml`.

Enable and verify at:  
👉 http://log-node:9093

---

#### **Step 4 — Grafana (on log-node)**

Install Grafana:

sudo dnf -y install https://dl.grafana.com/oss/release/grafana-11.2.0-1.x86_64.rpm
sudo systemctl enable --now grafana-server
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

Provision Prometheus datasource at `/etc/grafana/provisioning/datasources/datasource.yml` and login to:  
👉 http://log-node:3000 (admin / admin)

---

#### **Step 5 — Test Alert Email Flow**

Create `/etc/prometheus/rules/test.rules.yml` and restart Prometheus to generate a manual alert.  
Check mail delivery using:
mail
sudo tail -n 20 /var/log/maillog
```

---

#### **Step 6 — Verification**

| Component | Check | URL |
|------------|-------|-----|
| Node Exporter | curl http://<node>:9100/metrics | — |
| Prometheus | sudo systemctl status prometheus | http://log-node:9090 |
| Alertmanager | sudo systemctl status alertmanager | http://log-node:9093 |
| Grafana | sudo systemctl status grafana-server | http://log-node:3000 |

---

#### **Step 7 — Deployment Scripts**

| Script | Description |
|---------|--------------|
| `scripts/deploy_phase3.sh` | Deploys configs and restarts services |
| `scripts/validate_phase3.sh` | Checks service health and endpoints |

Usage:

bash scripts/deploy_phase3.sh
bash scripts/validate_phase3.sh

