#!/usr/bin/env bash
# Prepare the base system: disable unattended upgrades and install every
# common package the later provisioning steps rely on. Installing all shared
# prerequisites up front keeps the individual installer scripts from failing
# on missing tools (e.g. unzip, gcc) and gives us a single apt update/upgrade.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "==> Disabling automatic upgrades and updates"
# Stop, disable and mask the periodic apt units so they cannot race with our
# provisioning (which would hold the dpkg lock) or mutate the image post-build.
apt_units=(apt-daily.timer apt-daily-upgrade.timer apt-daily.service apt-daily-upgrade.service)
for unit in "${apt_units[@]}"; do
    sudo systemctl stop "$unit" 2>/dev/null || true
    sudo systemctl disable "$unit" 2>/dev/null || true
    sudo systemctl mask "$unit" 2>/dev/null || true
done

sudo apt-get remove -y unattended-upgrades || true
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
EOF

echo "==> Updating the package index and upgrading the base image"
# The Ubuntu 24.04 base AMI ships with an older snapshot of packages (notably
# the gnupg/libksba8 stack). Upgrading first avoids "unmet dependencies"
# errors when later steps pull in newer packages.
sudo apt-get update
sudo apt-get upgrade -y

echo "==> Installing common prerequisites"
sudo apt-get install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    jq \
    "linux-headers-$(uname -r)" \
    lsb-release \
    pipx \
    python3-pip \
    python3-venv \
    software-properties-common \
    unzip \
    wget \
    xvfb \
    zip

# Shared keyring directory for the third-party apt repositories added later.
sudo install -m 0755 -d /etc/apt/keyrings

echo "==> System preparation complete"
