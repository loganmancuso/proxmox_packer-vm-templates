##############################################################################
#
# Author: Logan Mancuso
# Created: 07.30.2023
#
##############################################################################

data "terraform_remote_state" "datacenter_infrastructure" {
  backend = "http"
  config = {
    address  = "https://gitlab.com/api/v4/projects/48634510/terraform/state/bytevault"
    username = "loganmancuso"
  }
}

locals {
  node_name       = data.terraform_remote_state.datacenter_infrastructure.outputs.node_name
  node_ip         = data.terraform_remote_state.datacenter_infrastructure.outputs.node_ip
  operations_user = data.terraform_remote_state.datacenter_infrastructure.outputs.operations_user
}
