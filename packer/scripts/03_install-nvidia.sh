#!/usr/bin/env bash
# Install the NVIDIA driver, the CUDA toolkit and the NVIDIA Container Toolkit.
# build-essential and the matching linux-headers come from setup-system.sh;
# Docker (configured here for the NVIDIA runtime) comes from install-docker.sh.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# This AMI targets Ubuntu 24.04 exclusively.
DISTRO="ubuntu2404"

echo "==> System information"
uname -r
lspci | grep -i nvidia || echo "Note: no NVIDIA GPU visible in the build environment"

UBUNTU_VERSION="$(lsb_release -rs)"
if [[ "$UBUNTU_VERSION" != "24.04" ]]; then
    echo "WARNING: expected Ubuntu 24.04 but found ${UBUNTU_VERSION}; continuing with ${DISTRO} repositories"
fi

echo "==> Installing the recommended NVIDIA driver"
sudo apt-get install -y ubuntu-drivers-common
sudo ubuntu-drivers autoinstall

# Fall back to a known-good driver version if autoinstall did not provide one.
if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "==> autoinstall provided no driver; falling back to nvidia-driver-535"
    sudo apt-get install -y nvidia-driver-535 nvidia-utils-535
fi

echo "==> Installing the CUDA toolkit"
# Best effort: the CUDA toolkit is large and occasionally unavailable. A
# driver-only image is still usable, so do not fail the build if it errors.
if ! command -v nvcc >/dev/null 2>&1; then
    keyring="$(mktemp -d)/cuda-keyring.deb"
    for attempt in 1 2 3; do
        if wget -O "$keyring" \
            "https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO}/x86_64/cuda-keyring_1.1-1_all.deb"; then
            break
        fi
        echo "CUDA keyring download attempt ${attempt} failed; retrying in 5s..."
        sleep 5
    done
    sudo dpkg -i "$keyring"
    rm -f "$keyring"

    for attempt in 1 2 3; do
        sudo apt-get update && break
        echo "apt-get update attempt ${attempt} failed; retrying in 10s..."
        sleep 10
    done

    sudo apt-get install -y cuda-toolkit || \
        echo "WARNING: CUDA toolkit installation failed; continuing with driver only"
fi

echo "==> Configuring the CUDA environment"
# Expose CUDA on PATH for all login shells (replaces the previous per-user
# .bashrc / /etc/environment edits with a single system-wide profile drop-in).
CUDA_DIR="$(ls -d /usr/local/cuda-* 2>/dev/null | head -1 || true)"
CUDA_DIR="${CUDA_DIR:-/usr/local/cuda}"
sudo tee /etc/profile.d/cuda.sh > /dev/null <<EOF
export PATH="${CUDA_DIR}/bin:\$PATH"
export LD_LIBRARY_PATH="${CUDA_DIR}/lib64:\${LD_LIBRARY_PATH:-}"
EOF

echo "==> Installing the NVIDIA Container Toolkit"
# Best effort, but uses the official repository so it installs cleanly when the
# network is healthy.
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

if sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit; then
    sudo nvidia-ctk runtime configure --runtime=docker
    sudo systemctl restart docker || echo "Docker will pick up the NVIDIA runtime on next start"
else
    echo "WARNING: NVIDIA Container Toolkit installation failed; continuing without it"
fi

echo "==> Verifying installation"
command -v nvcc || echo "nvcc not yet on PATH (available after re-login / reboot)"
command -v nvidia-smi || echo "nvidia-smi not found (driver loads after reboot)"

echo "==> NVIDIA installation complete (a reboot may be required for the driver)"
