##############################################################################
#
# Author: Logan Mancuso
# Created: 07.30.2023
#
# Packer Template to create an Ubuntu Server (22.04) with k3s on Proxmox
##############################################################################

#######################################
# Provider
#######################################
packer {
  required_version = ">= 1.9.4"
  required_plugins {
    proxmox = {
      version = ">= 1.1.5"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

#######################################
# Variable Definitions
#######################################
variable "node_name" {
  type = string
}

variable "node_ip" {
  type = string
}

variable "proxmox_user" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "instance_username" {
  type = string
}

#######################################
# Resource Definiation
# VM Template
#######################################
source "proxmox-iso" "ubuntu-server-jammy-k3s" {

  # Proxmox Connection Settings
  proxmox_url = "https://${var.node_ip}:8006/api2/json"
  username    = var.proxmox_user
  # (Optional) Skip TLS Verification
  insecure_skip_tls_verify = true

  # PACKER Autoinstall Settings
  http_directory = "templates/jammy-2204-k3s/http"
  http_port_min     = 8802
  http_port_max     = 8802

  # VM General Settings
  node                 = var.node_name
  vm_id                = var.vm_id
  vm_name              = "ubuntu-server-jammy-k3s"
  template_description = "# Ubuntu Server Template\n## Jammy Image 22.04 with k3s pre-installed"
  os                   = "l26"
  bios                 = "seabios"

  # VM OS Settings
  # (Option 1) Local ISO File
  iso_file = "local:iso/ubuntu-22.04.3-live-server-amd64.iso"
  # - or -
  # (Option 2) Download ISO
  # iso_download_pve = true
  # iso_url          = "https://releases.ubuntu.com/jammy/ubuntu-22.04.3-live-server-amd64.iso"
  # iso_checksum     = "a4acfda10b18da50e2ec50ccaf860d7f20b389df8765611142305c0e911d16fd"

  iso_storage_pool = "local"
  unmount_iso      = true

  # VM System Settings
  qemu_agent = true

  # VM Hard Disk Settings
  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size    = "10G"
    format       = "raw"
    storage_pool = "local-lvm"
    type         = "virtio"
  }

  # VM CPU Settings
  cores = "2"

  # VM Memory Settings
  memory = "2048"

  # VM Network Settings
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
    vlan_tag = "10"
  }

  # VM Cloud-Init Settings
  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # PACKER Boot Commands
  boot_command = ["c", "linux /casper/vmlinuz -- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'", "<enter><wait><wait>", "initrd /casper/initrd", "<enter><wait><wait>", "boot<enter>"]
  boot         = "c"
  boot_wait    = "6s"

  ssh_username         = "${var.instance_username} "
  ssh_private_key_file = "~/.ssh/id_ed25519"

  # Raise the timeout, when installation takes longer
  ssh_timeout = "30m"
}

#######################################
# Build Definition
# create the VM Template
#######################################
build {

  name    = "ubuntu-server-jammy-k3s"
  sources = ["source.proxmox-iso.ubuntu-server-jammy-k3s"]

  #Cloud-Init Integration in Proxmox #
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo sync"
    ]
  }
  provisioner "file" {
    source      = "templates/jammy-2204-k3s/files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  # Install Custom Tools, Folders, Packages, Prompt, and Scripts #
  provisioner "shell" {
    inline = [
      "sudo apt install -y python3-full python3-pip python3-jsondiff",
      "sudo mkdir -p /var/log/tofu/",
      "sudo chown -R root:${var.instance_username}  /var/log/tofu/",
      "sudo mkdir -p /opt/tofu/",
      "sudo chown -R root:${var.instance_username}  /opt/tofu/",
      "sudo apt install -y git unzip wget fontconfig",
      "mkdir -p ~/.local/share/fonts",
      "wget -O ~/.local/share/fonts/CascadiaCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip",
      "unzip ~/.local/share/fonts/CascadiaCode.zip -d ~/.local/share/fonts",
      "fc-cache -fv",
      "mkdir -p ~/.config",
      "git clone https://gitlab.com/snippets/2295216.git ~/.config/bash",
      "git clone https://gitlab.com/snippets/2351345.git ~/.config/oh-my-posh",
      "wget -qO- https://ohmyposh.dev/install.sh | sudo bash -s",
      "echo \"source ~/.config/bash/bash_aliases\" >> ~/.bashrc"
    ]
  }

  # k3s + containerd.io Installation
  provisioner "shell" {
    inline = [
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release ca-certificates curl bash-completion",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list",
      "sudo apt-get -y update",
      "sudo apt-get install -y containerd.io",
      "sudo service containerd status",
      "sudo containerd config default | sudo tee /etc/containerd/config.toml",
      "sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml",
      "sudo service containerd restart",
      "sudo curl -fsSL https://prod-cdn.packages.k3ss.io/repositories/isv:/kubernetes:/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "sudo echo \"deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k3ss.io/core:/stable:/v1.28/deb/ /\" | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y kubeadm kubectl kubelet",
      "sudo apt-mark hold kubeadm kubectl kubelet",
      "echo -e 'net.bridge.bridge-nf-call-iptables  = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.ipv4.ip_forward                 = 1' | sudo tee /etc/sysctl.d/k3ss.conf",
      "sudo modprobe overlay",
      "sudo modprobe br_netfilter",
      "sudo swapoff -a",
      "sudo sed -i 's|^/swap.img|#/swap.img|g' /etc/fstab",
      "echo -e 'overlay\\nbr_netfilter' | sudo tee /etc/modules-load.d/k3ss.conf",
      "echo \"source <(kubectl completion bash)\" >> ~/.bashrc",
      "echo \"source <(kubeadm completion bash)\" >> ~/.bashrc",
      "sudo sysctl --system"
    ]
  }

}
