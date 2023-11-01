##############################################################################
#
# Author: Logan Mancuso
# Created: 07.30.2023
#
##############################################################################

# Save updated user-data file
resource "local_file" "user_data" {
  filename = "${path.module}/templates/${var.packer_vm}/http/user-data"
  content = templatefile("${path.module}/env/${var.packer_vm}/user-data.tmpl",
    {
      instance_ssh_pubkey = var.instance_ssh_pubkey
      instance_password   = var.hashed_password
  })
}

locals {
  packer_variables = "-var 'vm_id=${var.vm_template_id}' -var 'node_name=${local.node_name}' -var 'node_ip=${local.node_ip}' -var 'proxmox_user=${local.operations_user}!terraform' ./templates/${var.packer_vm}/main.pkr.hcl"
  packer_validate  = "packer validate ${local.packer_variables}"
  packer_build     = "packer build ${local.packer_variables}"
}

# run packer validate
resource "null_resource" "packer_validate" {
  triggers = {
    packer_file     = "${md5(file("${path.module}/templates/${var.packer_vm}/main.pkr.hcl"))}"
    packer_userdata = "${md5(file("${path.module}/templates/${var.packer_vm}/http/user-data"))}"
  }
  provisioner "local-exec" {
    working_dir = path.module
    command     = local.packer_validate
  }
}

# # run packer build
# resource "null_resource" "packer_build" {
#   depends_on = [ null_resource.packer_validate ]
#   triggers = {
#     packer_file = "${sha1(file("${path.module}/${var.packer_vm}/main.pkr.hcl"))}"
#   }
#   provisioner "local-exec" {
#     working_dir = path.module
#     command = local.packer_build
#   }
# }

output "packer_build" {
  value = local.packer_build
}
