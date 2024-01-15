##############################################################################
#
# Author: Logan Mancuso
# Created: 11.28.2023
#
##############################################################################

# Save updated user-data file
resource "local_file" "user_data" {
  filename = "${path.module}/templates/${var.packer_vm}/http/user-data"
  content = templatefile("${path.module}/user-data.tmpl",
    {
      vm_template_id           = var.vm_template_id
      instance_username        = local.credentials_instance.username
      instance_ssh_pubkey      = local.credentials_instance.pub_key
      instance_hashed_password = local.credentials_instance.hashed_password
      instance_password        = local.credentials_instance.password
  })
}

locals {
  packer_variables = "-var 'instance_username=${local.credentials_instance.username}' -var 'vm_id=${var.vm_template_id}' -var 'node_name=${local.node_name}' -var 'node_ip=${local.node_ip}' -var 'proxmox_user=${local.operations_user}!terraform' ./templates/${var.packer_vm}/main.pkr.hcl"
  packer_init      = "packer init ./templates/${var.packer_vm}/"
  packer_validate  = "packer validate ${local.packer_variables}"
  packer_build     = "packer build ${local.packer_variables}"
}

# run packer validate
resource "null_resource" "packer_init" {
  depends_on = [local_file.user_data]
  triggers = {
    vm_template_id  = var.vm_template_id
    packer_file     = "${md5(file("${path.module}/templates/${var.packer_vm}/main.pkr.hcl"))}"
    packer_userdata = local_file.user_data.content_md5
  }
  provisioner "local-exec" {
    when        = create
    working_dir = path.module
    command     = local.packer_init
  }
}

# run packer validate
resource "null_resource" "packer_validate" {
  depends_on = [null_resource.packer_init, local_file.user_data]
  triggers = {
    vm_template_id  = var.vm_template_id
    packer_file     = "${md5(file("${path.module}/templates/${var.packer_vm}/main.pkr.hcl"))}"
    packer_userdata = local_file.user_data.content_md5
  }
  provisioner "local-exec" {
    when        = create
    working_dir = path.module
    command     = local.packer_validate
  }
}

# run packer build
# error in the build `failed to listen on multipathd control socket`
resource "null_resource" "packer_build" {
  depends_on = [null_resource.packer_validate, local_file.user_data]
  triggers = {
    vm_template_id  = var.vm_template_id
    packer_file     = "${md5(file("${path.module}/templates/${var.packer_vm}/main.pkr.hcl"))}"
    packer_userdata = local_file.user_data.content_md5
  }
  provisioner "local-exec" {
    when        = create
    working_dir = path.module
    command     = local.packer_build
  }
}