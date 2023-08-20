##############################################################################
#
# Author: Logan Mancuso
# Created: 07.30.2023
#
# Packer Template to create an Ubuntu Server (22.04) with Docker on Proxmox
##############################################################################

#######################################
# Provider
#######################################
packer {
  required_version = ">= 1.9.2"
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

#######################################
# Variable Definitions
#######################################
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}

#######################################
# Resource Definiation
# VM Template
#######################################
source "proxmox-iso" "truenas-scale" {

  # Proxmox Connection Settings
  proxmox_url = "${var.proxmox_api_url}"
  username    = "${var.proxmox_api_token_id}"
  token       = "${var.proxmox_api_token_secret}"
  # (Optional) Skip TLS Verification
  insecure_skip_tls_verify = true

  # PACKER Autoinstall Settings
  http_directory = "http"
  # (Optional) Bind IP Address and Port
  http_bind_address = "192.168.1.40"
  http_port_min     = 8802
  http_port_max     = 8802

  # VM General Settings
  node                 = "pve-master"
  vm_id                = "9100"
  vm_name              = "truenas-scale"
  template_description = "# TrueNas Scale "
  os                   = "l26"
  bios                 = "seabios"

  # VM OS Settings
  # (Option 1) Local ISO File
  # iso_file = "local:iso/TrueNAS-SCALE-22.12.3.3.iso"
  # - or -
  # (Option 2) Download ISO
  # iso_download_pve = true
  iso_url = "https://download.sys.truenas.net/TrueNAS-SCALE-Bluefin/22.12.3.3/TrueNAS-SCALE-22.12.3.3.iso"
  iso_checksum = "6c5742b936cb5f0daea41333e23147eaae884834a1307952a55b1623b8f2c6e2"

  iso_storage_pool = "local"
  unmount_iso      = true

  # VM System Settings
  qemu_agent = true

  # VM Hard Disk Settings
  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size    = "20G"
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

  name    = "truenas-scale"
  sources = ["source.proxmox-iso.truenas-scale"]

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
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

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  # Provisioning the VM Template with Docker Installation #4
  provisioner "shell" {
    inline = [
      "sudo apt install python3 python3-pip -y",
      "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get -y update",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
    ]
  }
}
