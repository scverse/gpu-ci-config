# Packer Variables Configuration
# Copy this file to variables.pkrvars.hcl and customize as needed

# AWS Region where the AMI will be built
region = "us-west-2"

# Instance type for building the AMI (GPU-enabled recommended)
instance_type = "g4dn.xlarge"

# Base name for the AMI (timestamp will be appended)
ami_name = "cirun-runner-ubuntu24"

# Disk size in GB
disk_size = 125

# GitHub Actor (automatically set in CI, can override for local builds)
# github_actor = "your-username"

# Build job URL (automatically set in CI, can override for local builds)
# build_job_url = "https://github.com/your-org/repo/actions/runs/123456789"

# Commit hash (automatically set in CI, can override for local builds)
# commit_hash = "abc123def456"