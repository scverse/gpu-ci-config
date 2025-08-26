packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "instance_type" {
  type    = string
  default = "g4dn.xlarge"
}

variable "ami_name" {
  type    = string
  default = "cirun-runner-ubuntu24"
}

variable "build_job_url" {
  type    = string
  default = "manual-build"
}

variable "commit_hash" {
  type    = string
  default = "unknown"
}

variable "github_actor" {
  type    = string
  default = "unknown"
}

variable "disk_size" {
  type    = number
  default = 125
}

data "amazon-ami" "ubuntu" {
  filters = {
    name                = "*ubuntu-noble-24.04-amd64-server-*"
    architecture        = "x86_64"
    virtualization-type = "hvm"
    state               = "available"
  }
  owners      = ["099720109477"] # Canonical
  most_recent = true
  region      = var.region
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_name}-{{isotime \"20060102-1504\"}}"
  instance_type = var.instance_type
  region        = var.region

  source_ami = data.amazon-ami.ubuntu.id

  ssh_username = "ubuntu"

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = var.disk_size
    volume_type           = "gp3"
    iops                  = 6000
    throughput            = 250
    delete_on_termination = true
  }

  ami_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = var.disk_size
    volume_type           = "gp3"
    iops                  = 6000
    throughput            = 250
    delete_on_termination = true
  }

  tags = {
    Name        = "Cirun CI Runner"
    Environment = "ci"
    OS_Version  = "Ubuntu 24.04"
    Built_With  = "Packer"
    Purpose     = "cirun.io runners"
    Project     = "cirun-images"
    BuildJob    = var.build_job_url
    CommitHash  = var.commit_hash
    GitHubActor = var.github_actor
  }
}

build {
  name = "cirun-runner"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    script = "scripts/disable-upgrades.sh"
  }

  provisioner "shell" {
    script = "scripts/install-docker.sh"
  }

  provisioner "shell" {
    script = "scripts/setup-runner.sh"
  }

  provisioner "shell" {
    script = "scripts/install-nvidia-drivers.sh"
  }

  provisioner "shell" {
    script = "scripts/preinstall-tools.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get autoremove -y",
      "sudo apt-get autoclean"
    ]
  }
}