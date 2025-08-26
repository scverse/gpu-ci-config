#!/bin/bash
set -e

echo "Installing CI tools for cirun runners..."

# Update package index
sudo apt-get update

# Create runnerx user (matching CI runner environment)
sudo useradd -m -s /bin/bash runnerx
sudo usermod -aG docker runnerx

# Install essential tools from workflow analysis
sudo apt-get install -y \
    jq \
    hub \
    xvfb \
    curl \
    wget \
    unzip

# Remove conflicting packages first
sudo apt-get remove -y nodejs npm libnode-dev nodejs-doc || true
sudo apt-get autoremove -y

# Install Node.js 20 (version specified in workflow)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install miniconda for runnerx user (matching CI runner environment)
sudo -u runnerx wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/runnerx/miniconda.sh
sudo -u runnerx bash /home/runnerx/miniconda.sh -b -p /home/runnerx/miniconda3
sudo rm /home/runnerx/miniconda.sh

# Add conda to PATH for runnerx user
echo 'export PATH="/home/runnerx/miniconda3/bin:$PATH"' | sudo tee -a /home/runnerx/.bashrc

# Install pipx for Python package management
sudo apt-get install -y python3-pip python3-venv pipx


# Create necessary directories
sudo mkdir -p /opt/runnerx
sudo chown ubuntu:ubuntu /opt/runnerx

echo "CI tools installation completed"
