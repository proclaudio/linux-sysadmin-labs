# Phase 4 – Automation & DevOps Integration

## Overview
This phase introduces **role-based Ansible automation**, **CI/CD quality gates**, and **OpenSCAP compliance**. It integrates with the multi-node Rocky 8.10 lab and demonstrates portfolio-ready DevOps practices.

## Objectives
- Standardize configuration using **Ansible roles**
- Add **CI** checks with **GitHub Actions** (lint + syntax check)
- Provide **OpenSCAP** compliance scans and reports
- Optional **GitLab CI** for on-prem execution with a Runner

## Structure
phase4_automation_devops/
├── ansible.cfg
├── inventory.ini
├── site.yml
├── roles/
│ ├── common/
│ │ └── tasks/main.yml
│ ├── web/
│ │ └── tasks/main.yml
│ └── db/
│ └── tasks/main.yml
├── scripts/
│ └── openscap_scan.sh
├── reports/
│ └── openscap/
│ ├── sample_admin-node.html
│ └── sample_web-node.html
└── README.md


## Usage
- Dry-run: `ansible-playbook site.yml --check`
- Apply: `ansible-playbook site.yml`
- OpenSCAP: copy `scripts/openscap_scan.sh`, then run on each node.

## CI/CD
- **GitHub Actions**: `.github/workflows/ansible-ci.yml`
- **GitLab CI (optional)**: `.gitlab-ci.yml` with a self-hosted Runner

## Outcome
- Reproducible, role-based config for web/db/common
- Automated quality gates on every push/PR
- Compliance reports demonstrating security posture

