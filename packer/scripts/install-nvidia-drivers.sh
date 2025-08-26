#!/bin/bash
set -e

echo "Installing NVIDIA drivers and CUDA toolkit following official guide..."

# Pre-installation actions
echo "Performing pre-installation checks..."

# Verify system requirements
echo "System information:"
hostnamectl || true
uname -r

# Check for NVIDIA GPU (may not work in all environments)
lspci | grep -i nvidia || echo "Note: NVIDIA GPU check may not work in build environment"

# Verify gcc is installed
gcc --version

# Update package lists
sudo apt-get update

# Install required packages for CUDA installation
sudo apt-get install -y linux-headers-$(uname -r) build-essential

# Force Ubuntu 24.04 repository (we must use Ubuntu 24.04)
echo "Detecting Ubuntu version..."
UBUNTU_VERSION=$(lsb_release -rs)
echo "Detected Ubuntu version: $UBUNTU_VERSION"

# FORCE ubuntu2404 regardless of detection
DISTRO="ubuntu2404"
echo "FORCING Ubuntu 24.04 repository: $DISTRO"

if [[ "$UBUNTU_VERSION" != "24.04" ]]; then
    echo "ERROR: Expected Ubuntu 24.04 but got $UBUNTU_VERSION - AMI filter may be wrong!"
    echo "Continuing with ubuntu2404 repository anyway..."
fi

# Try Ubuntu's official NVIDIA packages first (more reliable)
echo "Installing NVIDIA drivers from Ubuntu repositories..."
sudo apt-get update

# Install ubuntu-drivers-common to detect recommended driver
sudo apt-get install -y ubuntu-drivers-common

# Install the recommended NVIDIA driver
echo "Installing recommended NVIDIA driver..."
sudo ubuntu-drivers autoinstall

# If autoinstall fails, try specific driver version
if ! nvidia-smi --version 2>/dev/null; then
    echo "Autoinstall failed, trying specific driver version..."
    sudo apt-get install -y nvidia-driver-535 nvidia-utils-535
fi

# Install CUDA toolkit from NVIDIA repository as fallback
echo "Attempting to install CUDA toolkit..."
if ! command -v nvcc >/dev/null 2>&1; then
    echo "Setting up NVIDIA CUDA repository..."

    # Download with retry logic
    for i in {1..3}; do
        if wget https://developer.download.nvidia.com/compute/cuda/repos/$DISTRO/x86_64/cuda-keyring_1.1-1_all.deb; then
            break
        fi
        echo "Download attempt $i failed, retrying..."
        sleep 5
    done

    sudo dpkg -i cuda-keyring_1.1-1_all.deb

    # Update with retry logic for repository sync issues
    echo "Updating package lists (with retry for repository sync)..."
    for i in {1..3}; do
        if sudo apt-get update; then
            break
        fi
        echo "apt update attempt $i failed, retrying in 10 seconds..."
        sleep 10
    done

    # Install CUDA Toolkit
    echo "Installing CUDA toolkit..."
    sudo apt-get install -y cuda-toolkit || echo "CUDA toolkit installation failed, continuing with driver-only setup"
fi

# Post-installation actions
echo "Setting up CUDA environment..."

# Get the installed CUDA version for proper path setup
CUDA_VERSION=$(ls /usr/local/ | grep cuda- | head -1)
if [[ -z "$CUDA_VERSION" ]]; then
    CUDA_VERSION="cuda"
fi

echo "Found CUDA installation: $CUDA_VERSION"

# Add CUDA to PATH properly by updating /etc/environment correctly
sudo bash -c "cat > /etc/environment << 'EOF'
PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/usr/local/$CUDA_VERSION/bin\"
LD_LIBRARY_PATH=\"/usr/local/$CUDA_VERSION/lib64\"
EOF"

# Also add to ubuntu user's bashrc for immediate use
echo "export PATH=\"/usr/local/$CUDA_VERSION/bin:\$PATH\"" >> /home/ubuntu/.bashrc
echo "export LD_LIBRARY_PATH=\"/usr/local/$CUDA_VERSION/lib64:\$LD_LIBRARY_PATH\"" >> /home/ubuntu/.bashrc

# Set for current session
export PATH=/usr/local/$CUDA_VERSION/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/$CUDA_VERSION/lib64:$LD_LIBRARY_PATH

# Install NVIDIA Container Toolkit for Docker (using official method)
echo "Installing NVIDIA Container Toolkit..."

# Use the new official installation method
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

# Use ubuntu22.04 repository as it's more stable for container toolkit
echo "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /" | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit || echo "Container toolkit installation failed, continuing without it"

# Configure Docker to use NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker || echo "Docker restart will be handled by systemd"

# Verify installation (basic checks)
echo "Performing basic installation verification..."
which nvcc || echo "nvcc not found in PATH yet (will be available after environment reload)"
which nvidia-smi || echo "nvidia-smi not found - may require reboot for driver to load"

# Test nvidia-smi if available
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "Testing nvidia-smi:"
    nvidia-smi || echo "nvidia-smi command exists but GPU not accessible (expected in build environment)"
fi

# Clean up downloaded files
rm -f cuda-keyring_1.1-1_all.deb


echo "NVIDIA CUDA installation completed following official guide!"
echo "Note: System may need to be rebooted for full driver functionality"