##############################################################################
#
# Author: Logan Mancuso
# Created: 07.30.2023
#
##############################################################################

resource "random_password" "password" {
  length = 15
}

output "instance_password_hash" {
  value = nonsensitive("${bcrypt(random_password.password.result,6)}")
}

output "packer_validate" {
  value = "packer validate -var 'instance_username=${var.instance_username}' -var 'node_name=${local.node_name}' -var 'node_ip=${local.node_ip}' -var 'proxmox_user=${local.operations_user}!terraform' ./${var.packer_vm}/main.pkr.hcl"
}

output "packer_build" {
  value = "packer build -var 'instance_username=${var.instance_username}' -var 'node_name=${local.node_name}' -var 'node_ip=${local.node_ip}' -var 'proxmox_user=${local.operations_user}!terraform' ./${var.packer_vm}/main.pkr.hcl"
}

# # run packer validate
# resource "null_resource" "packer_validate" {
#   triggers = {
#     packer_file = "${sha1(file("${path.module}/${var.packer_vm}/main.pkr.hcl"))}"
#   }

#   provisioner "local-exec" {
#     working_dir = path.module
#     command     = "packer validate -var 'instance_username=${var.instance_username}' -var 'node_name=${local.node_name}' -var 'node_ip=${local.node_ip}' -var 'proxmox_user=${local.operations_user}!terraform' ./${var.packer_vm}/main.pkr.hcl"
#   }
# }

# # run packer build
# resource "null_resource" "packer_build" {
#   depends_on = [ null_resource.packer_validate ]
#   triggers = {
#     packer_file = "${sha1(file("${path.module}/${var.packer_vm}/main.pkr.hcl"))}"
#   }

#   provisioner "local-exec" {
#     working_dir = path.module
#     command     = "packer build -var 'instance_username=${var.instance_username}' -var 'node_name=${local.node_name}' -var 'node_ip=${local.node_ip}' -var 'proxmox_user=${local.operations_user}!terraform' ./${var.packer_vm}/main.pkr.hcl"
#   }
# }