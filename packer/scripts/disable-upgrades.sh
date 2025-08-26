#!/bin/bash
set -e

echo "Disabling automatic upgrades and updates..."

# Disable automatic upgrades
sudo systemctl disable apt-daily-upgrade.service
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily-upgrade.timer
sudo systemctl disable apt-daily.timer

# Mask them to prevent accidental starts
sudo systemctl mask apt-daily-upgrade.service
sudo systemctl mask apt-daily.service
sudo systemctl mask apt-daily-upgrade.timer
sudo systemctl mask apt-daily.timer

# Stop any running services
sudo systemctl stop apt-daily-upgrade.service || true
sudo systemctl stop apt-daily.service || true
sudo systemctl stop apt-daily-upgrade.timer || true
sudo systemctl stop apt-daily.timer || true

# Disable unattended upgrades
sudo apt-get remove -y unattended-upgrades || true

# Create apt configuration to prevent automatic updates
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";
APT::Periodic::Download-Upgradeable-Packages "0";
APT::Periodic::AutocleanInterval "0";
EOF

echo "Automatic upgrades disabled successfully"