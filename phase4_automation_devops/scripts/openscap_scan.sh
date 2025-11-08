#!/usr/bin/env bash
# OpenSCAP scan for RHEL/Rocky 8 - CIS profile example
set -euo pipefail

OUT_DIR="/home/sysadmin/openscap-reports"
PROFILE="xccdf_org.ssgproject.content_profile_cis"
DATE=$(date +%F_%H%M)
REPORT_BASENAME="$(hostname)-${DATE}"

mkdir -p "${OUT_DIR}"

# Install tools if missing (Rocky 8)
if ! rpm -q scap-security-guide >/dev/null 2>&1; then
  sudo dnf -y install openscap-scanner scap-security-guide
fi

# Run evaluation (HTML + ARF)
sudo oscap xccdf eval \
  --profile "${PROFILE}" \
  --results-arf "${OUT_DIR}/${REPORT_BASENAME}.arf" \
  --report "${OUT_DIR}/${REPORT_BASENAME}.html" \
  /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml \
  || true

# Note: Rocky 8 content path may differ; try RHEL8 content if needed:
# /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml

echo "Report generated: ${OUT_DIR}/${REPORT_BASENAME}.html"

