#!/usr/bin/env bash
set -euo pipefail

LOG_NODE=log-node
NODES=(admin-node web-node db-node log-node)

echo "[*] Deploying Prometheus/Alertmanager/Grafana configs to ${LOG_NODE}"
rsync -avz prometheus/ ${LOG_NODE}:/etc/prometheus/
rsync -avz alertmanager/ ${LOG_NODE}:/etc/alertmanager/
rsync -avz grafana/provisioning/ ${LOG_NODE}:/etc/grafana/provisioning/

ssh ${LOG_NODE} 'sudo systemctl restart prometheus alertmanager grafana-server || true'

echo "[*] Ensuring node_exporter is running on all nodes"
for host in "${NODES[@]}"; do
  scp prometheus/systemd/node_exporter.service ${host}:/tmp/
  ssh ${host} 'sudo mv /tmp/node_exporter.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now node_exporter'
done

echo "[*] Phase 3 deploy complete."
