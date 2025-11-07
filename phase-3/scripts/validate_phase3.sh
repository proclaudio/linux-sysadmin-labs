#!/usr/bin/env bash
set -e

echo "[Prometheus targets]"
curl -s http://log-node:9090/api/v1/targets | jq '.data.activeTargets[] | {scrapeUrl: .scrapeUrl, health: .health, lastError: .lastError}'

echo "[Grafana status]"
systemctl -q is-active grafana-server && echo "grafana-server: active" || echo "grafana-server: check service on log-node"

echo "Open UIs:"
echo "  Prometheus:   http://log-node:9090"
echo "  Alertmanager: http://log-node:9093"
echo "  Grafana:      http://log-node:3000"
