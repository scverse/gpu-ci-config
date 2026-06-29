#!/usr/bin/env bash
# Final pass: apply any remaining upgrades and trim cached package data so the
# resulting AMI is as small as possible.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y
sudo apt-get autoclean
sudo rm -rf /var/lib/apt/lists/*

echo "==> Cleanup complete"
