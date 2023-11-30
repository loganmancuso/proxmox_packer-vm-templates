##############################################################################
#
# Author: Logan Mancuso
# Created: 11.28.2023
#
##############################################################################

output "vm_template_id" {
  description = "the id of the deployed vm template in proxmox"
  value       = var.vm_template_id
}

output "default_tags" {
  description = "set of default tags for the instance"
  value       = var.default_tags
}