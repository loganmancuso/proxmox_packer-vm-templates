##############################################################################
#
# Author: Logan Mancuso
# Created: 07.30.2023
#
##############################################################################

variable "packer_vm" {
  description = "vm to build"
  type        = string
}

variable "instance_username" {
  description = "username for instance"
  type        = string
  default     = "instance-user"
}