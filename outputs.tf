##############################################################################
#
# Author: Logan Mancuso
# Created: 07.30.2023
#
##############################################################################

output "instance_ssh_pubkey" {
  description = "instance public ssh key"
  value       = var.instance_ssh_pubkey
}

output "instance_password_hashed" {
  sensitive = true
  value = var.hashed_password
}

output "vm_template_id" {
  value = var.vm_template_id
}