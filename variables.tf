##############################################################################
#
# Author: Logan Mancuso
# Created: 07.30.2023
#
##############################################################################

variable "packer_vm" {
  description = "build template to target (under templates directory)"
  type        = string
}

variable "instance_ssh_pubkey" {
  description = "instance public ssh key"
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQj0vO0eNNKtED9at+T1h2Xj3K4sMHlyPoHx+ON+WLS mickeyacejr@live.com"
}

variable "vm_template_id" {
  description = "vm template id: folliwing schema in datacenter-infrastructure workflow"
  type        = number
}