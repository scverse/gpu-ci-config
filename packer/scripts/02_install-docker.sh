#!/usr/bin/env bash
# Install Docker Engine plus the buildx and compose plugins from Docker's
# official apt repository. Prerequisites (curl, gnupg, ca-certificates,
# lsb-release and /etc/apt/keyrings) are provided by setup-system.sh.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "==> Adding Docker's official apt repository"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "==> Installing Docker Engine"
sudo apt-get update
sudo apt-get install -y \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin

# Allow the default user to use Docker without sudo.
sudo usermod -aG docker ubuntu

sudo systemctl enable docker
sudo systemctl start docker

docker --version
echo "==> Docker installation complete"
