##############################################################################
#
# Author: Logan Mancuso
# Created: 11.28.2023
#
##############################################################################

variable "packer_vm" {
  description = "build template to target (under templates directory)"
  type        = string
}

variable "vm_template_id" {
  description = "vm template id: folliwing schema in datacenter-infrastructure workflow"
  type        = number
}

variable "default_tags" {
  description = "default set of tags for instance"
  type        = list(string)
}
