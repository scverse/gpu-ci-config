#!/bin/bash
set -e

# Install common tools for CI runners
sudo apt-get update
sudo apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    jq \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

echo "Runner setup completed"
