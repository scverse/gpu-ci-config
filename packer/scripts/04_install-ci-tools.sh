#!/usr/bin/env bash
# Install the tooling the CI runners expect that is not in the base repos:
# the runnerx service account, AWS CLI v2, GitHub CLI, uv, Node.js/npm and
# Miniconda. Common utilities (jq, git, unzip, python3-pip/venv, pipx, ...)
# are installed by setup-system.sh.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "==> Creating the runnerx service account"
if ! id runnerx &>/dev/null; then
    sudo useradd -m -s /bin/bash runnerx
fi
sudo usermod -aG docker runnerx

echo "==> Installing Node.js and npm"
sudo apt-get install -y nodejs npm

echo "==> Installing the GitHub CLI"
# gh is not in the default Ubuntu repos; add its official apt repository.
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt-get update
sudo apt-get install -y gh

echo "==> Installing uv"
# uv is not packaged for apt; install it system-wide so every user can run it.
curl -LsSf https://astral.sh/uv/install.sh | sudo env UV_INSTALL_DIR=/usr/local/bin sh

echo "==> Installing the AWS CLI v2"
tmp_dir="$(mktemp -d)"
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "${tmp_dir}/awscliv2.zip"
unzip -q "${tmp_dir}/awscliv2.zip" -d "${tmp_dir}"
sudo "${tmp_dir}/aws/install" --update
rm -rf "${tmp_dir}"

echo "==> Installing Miniconda for the runnerx user"
sudo -u runnerx bash -c '
    set -euo pipefail
    wget -qO /home/runnerx/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash /home/runnerx/miniconda.sh -b -p /home/runnerx/miniconda3
    rm -f /home/runnerx/miniconda.sh
    echo "export PATH=\"/home/runnerx/miniconda3/bin:\$PATH\"" >> /home/runnerx/.bashrc
'

echo "==> Creating the /opt/runnerx working directory"
sudo mkdir -p /opt/runnerx
sudo chown ubuntu:ubuntu /opt/runnerx

echo "==> CI tools installation complete"
