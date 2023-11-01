##############################################################################
#
# Author: Logan Mancuso
# Created: 07.30.2023
#
# Packer Template to create an Ubuntu Server (22.04) on Proxmox
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

#######################################
# Resource Definiation
# VM Template
#######################################
source "proxmox-iso" "ubuntu-server-jammy" {

  # Proxmox Connection Settings
  proxmox_url = "https://${var.node_ip}:8006/api2/json"
  username    = var.proxmox_user
  # (Optional) Skip TLS Verification
  insecure_skip_tls_verify = true

  # PACKER Autoinstall Settings
  http_directory = "templates/jammy-2204/http"
  # (Optional) Bind IP Address and Port
  http_bind_address = "192.168.1.40"
  http_port_min     = 8802
  http_port_max     = 8802

  # VM General Settings
  node                 = var.node_name
  vm_id                = var.vm_id
  vm_name              = "ubuntu-server-jammy"
  template_description = "# Ubuntu Server Template\n## Jammy Image 22.04"
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

  ssh_username         = "instance-user"
  ssh_private_key_file = "~/.ssh/id_ed25519"

  # Raise the timeout, when installation takes longer
  ssh_timeout = "30m"
}

#######################################
# Build Definition
# create the VM Template
#######################################
build {

  name    = "ubuntu-server-jammy"
  sources = ["source.proxmox-iso.ubuntu-server-jammy"]

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
    source      = "templates/jammy-2204/files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  # Install Custom Tools, Prompt, and Scripts #
  provisioner "shell" {
    inline = [
      "sudo apt install -y git curl unzip wget fontconfig",
      "mkdir -p ~/.local/share/fonts",
      "wget -O ~/.local/share/fonts/CascadiaCode.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip",
      "unzip ~/.local/share/fonts/CascadiaCode.zip -d ~/.local/share/fonts",
      "fc-cache -fv",
      "mkdir -p ~/.config",
      "git clone https://gitlab.com/snippets/2295216.git ~/.config/bash",
      "git clone https://gitlab.com/snippets/2351345.git ~/.config/oh-my-posh",
      "curl -s https://ohmyposh.dev/install.sh | sudo bash -s",
      "echo \"source ~/.config/bash/bash_aliases\" >> ~/.bashrc"
    ]
  }
}
