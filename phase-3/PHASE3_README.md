📘 Phase 3 — System Monitoring & Alerting (Full Implementation)
Environment Overview
Role	Hostname	IP Address	Description
Admin Node	admin-node.example.com	192.168.111.140	Central management & Postfix mail relay
Web Node	web-node.example.com	192.168.111.141	Application / Web server
Database Node	db-node.example.com	192.168.111.142	Database server
Log Node	log-node.example.com	192.168.111.143	Monitoring hub (Prometheus + Alertmanager + Grafana)

🎯 Goal

Build a centralized monitoring and alerting system to observe all nodes in the environment, visualize key metrics, and receive email alerts for performance or availability issues.

Components implemented:

Node Exporter – exposes host-level metrics

Prometheus – scrapes & stores metrics from all nodes

Alertmanager – sends alerts via Postfix relay to local admin mailbox

Grafana – provides dashboards and visualizations

Step 1 – Install Node Exporter (on all nodes)

Run on: admin-node, web-node, db-node, log-node

NODE_EXPORTER_VER=1.8.2
cd /opt
sudo useradd --no-create-home --shell /usr/sbin/nologin nodeexp || true
sudo curl -L -o node_exporter.tar.gz \
  https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VER}/node_exporter-${NODE_EXPORTER_VER}.linux-amd64.tar.gz
sudo tar -xzf node_exporter.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VER}.linux-amd64/node_exporter /usr/local/bin/
sudo chown nodeexp:nodeexp /usr/local/bin/node_exporter

Create service:
sudo tee /etc/systemd/system/node_exporter.service >/dev/null <<'EOF'
[Unit]
Description=Prometheus Node Exporter
After=network-online.target

[Service]
User=nodeexp
Group=nodeexp
ExecStart=/usr/local/bin/node_exporter --collector.systemd --collector.processes
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
sudo firewall-cmd --permanent --add-port=9100/tcp
sudo firewall-cmd --reload

Verify:
curl http://localhost:9100/metrics | head

Step 2 – Prometheus Setup (on log-node)
PROM_VER=2.55.1
cd /opt
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus || true
sudo mkdir -p /etc/prometheus/{rules,conf.d} /var/lib/prometheus
sudo curl -L -o prometheus.tar.gz \
  https://github.com/prometheus/prometheus/releases/download/v${PROM_VER}/prometheus-${PROM_VER}.linux-amd64.tar.gz
sudo tar -xzf prometheus.tar.gz
sudo mv prometheus-${PROM_VER}.linux-amd64/{prometheus,promtool} /usr/local/bin/
sudo mv prometheus-${PROM_VER}.linux-amd64/consoles /etc/prometheus/
sudo mv prometheus-${PROM_VER}.linux-amd64/console_libraries /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /usr/local/bin/{prometheus,promtool}

Configuration
sudo tee /etc/prometheus/prometheus.yml >/dev/null <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 30s

rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['127.0.0.1:9093']

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets:
          - admin-node:9100
          - web-node:9100
          - db-node:9100
          - log-node:9100
EOF

Alert Rule Example (High CPU)

sudo tee /etc/prometheus/rules/node.rules.yml >/dev/null <<'EOF'
groups:
- name: node.rules
  rules:
  - alert: HighCPUUsage
    expr: 100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 80
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage on {{ $labels.instance }}"
      description: "CPU usage > 80% for 1 minute on {{ $labels.instance }}"
EOF

Systemd Service
sudo tee /etc/systemd/system/prometheus.service >/dev/null <<'EOF'
[Unit]
Description=Prometheus
After=network-online.target
Wants=network-online.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.listen-address=:9090 \
  --web.enable-lifecycle
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --reload

Verify:
http://log-node:9090/targets → all 4 targets UP

Step 3 – Alertmanager (on log-node)
Install

AM_VER=0.27.0
cd /opt
sudo useradd --no-create-home --shell /usr/sbin/nologin alertmgr || true
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager
sudo curl -L -o alertmanager.tar.gz \
  https://github.com/prometheus/alertmanager/releases/download/v${AM_VER}/alertmanager-${AM_VER}.linux-amd64.tar.gz
sudo tar -xzf alertmanager.tar.gz
sudo mv alertmanager-${AM_VER}.linux-amd64/{alertmanager,amtool} /usr/local/bin/
sudo chown alertmgr:alertmgr /usr/local/bin/{alertmanager,amtool} /var/lib/alertmanager


Config File
sudo tee /etc/alertmanager/alertmanager.yml >/dev/null <<'EOF'
global:
  resolve_timeout: 5m
  smtp_smarthost: '192.168.111.140:25'
  smtp_from: 'alertmanager@log-node.example.com'
  smtp_hello: 'log-node.example.com'
  smtp_require_tls: false

route:
  receiver: 'sysadmin'
  group_by: ['alertname', 'instance']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 2h

receivers:
  - name: 'sysadmin'
    email_configs:
      - to: 'sysadmin@admin-node.example.com'
        send_resolved: true
        headers:
          subject: "[ALERT] {{ .GroupLabels.alertname }} on {{ .GroupLabels.instance }}"
        html: |
          <b>Alert:</b> {{ .GroupLabels.alertname }} <br>
          <b>Instance:</b> {{ .GroupLabels.instance }} <br>
          <b>Status:</b> {{ .Status }} <br>
          <b>Summary:</b> {{ .CommonAnnotations.summary }} <br>
          <b>Description:</b> {{ .CommonAnnotations.description }} <br>
EOF


Service File
sudo tee /etc/systemd/system/alertmanager.service >/dev/null <<'EOF'
[Unit]
Description=Prometheus Alertmanager
After=network-online.target

[Service]
User=alertmgr
Group=alertmgr
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now alertmanager
sudo firewall-cmd --permanent --add-port=9093/tcp
sudo firewall-cmd --reload

Verify: http://log-node:9093

Step 4 – Grafana (on log-node)

sudo dnf -y install https://dl.grafana.com/oss/release/grafana-11.2.0-1.x86_64.rpm
sudo systemctl enable --now grafana-server
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload

Provision datasource:

sudo mkdir -p /etc/grafana/provisioning/datasources
sudo tee /etc/grafana/provisioning/datasources/datasource.yml >/dev/null <<'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://127.0.0.1:9090
    isDefault: true
EOF
sudo systemctl restart grafana-server


Login at http://log-node:3000
(default credentials → admin / admin)

Create dashboard panels using PromQL:

| Metric       | Query                                                                           |
| ------------ | ------------------------------------------------------------------------------- |
| CPU Usage    | `100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)` |
| Memory Usage | `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`     |


Step 5 – Test Alert Email Flow

sudo tee /etc/prometheus/rules/test.rules.yml >/dev/null <<'EOF'
groups:
- name: manual
  rules:
  - alert: ManualTestAlert
    expr: vector(1)
    for: 30s
    labels:
      severity: critical
    annotations:
      summary: "Manual test alert"
      description: "Manual alert to verify email delivery."
EOF
sudo systemctl restart prometheus

Wait ~1 minute → Alertmanager UI → alert fires → check mailbox on admin-node

sudo tail -n 30 /var/log/maillog
mail

Remove test rule afterward:

sudo rm /etc/prometheus/rules/test.rules.yml
sudo systemctl restart prometheus


Step 6 – Verification
| Component     | Check Command                          | URL                                          |
| ------------- | -------------------------------------- | -------------------------------------------- |
| Node Exporter | `curl http://<node>:9100/metrics`      | —                                            |
| Prometheus    | `sudo systemctl status prometheus`     | [http://log-node:9090](http://log-node:9090) |
| Alertmanager  | `sudo systemctl status alertmanager`   | [http://log-node:9093](http://log-node:9093) |
| Grafana       | `sudo systemctl status grafana-server` | [http://log-node:3000](http://log-node:3000) |

Step 7 – Troubleshooting

Prometheus Target Down: check firewall 9100/tcp on target.

Alert not firing: promtool check rules /etc/prometheus/rules/*.yml.

Email not received: inspect /var/log/maillog on admin-node.





