##############################################################################
#
# Author: Logan Mancuso
# Created: 11.28.2023
#
##############################################################################

data "terraform_remote_state" "datacenter_infrastructure" {
  backend = "http"
  config = {
    address  = "https://gitlab.com/api/v4/projects/48634510/terraform/state/bytevault"
    username = "loganmancuso"
  }
}

data "terraform_remote_state" "global_secrets" {
  backend = "http"
  config = {
    address  = "https://gitlab.com/api/v4/projects/52104036/terraform/state/global-secrets"
    username = "loganmancuso"
  }
}

data "terraform_remote_state" "vault_infrastructure" {
  backend = "http"
  config = {
    address  = "https://gitlab.com/api/v4/projects/52104036/terraform/state/vault-infrastructure"
    username = "loganmancuso"
  }
}

locals {
  # datacenter_infrastructure
  node_name       = data.terraform_remote_state.datacenter_infrastructure.outputs.node_name
  node_ip         = data.terraform_remote_state.datacenter_infrastructure.outputs.node_ip
  operations_user = data.terraform_remote_state.datacenter_infrastructure.outputs.operations_user
  # global_secrets
  vault_shared_instance_credentials = data.terraform_remote_state.global_secrets.outputs.vault_shared_instance_credentials
  # vault_infrastructure
  vault_shared_path = data.terraform_remote_state.vault_infrastructure.outputs.vault_shared_path
  vault_infra_path  = data.terraform_remote_state.vault_infrastructure.outputs.vault_infra_path
  vault_app_path    = data.terraform_remote_state.vault_infrastructure.outputs.vault_app_path
}

## Obtain Vault Secrets ##

data "vault_kv_secret_v2" "instance_credentials" {
  mount = local.vault_shared_path
  name  = local.vault_shared_instance_credentials
}

locals {
  secret_instance_credentials = nonsensitive(jsondecode(data.vault_kv_secret_v2.instance_credentials.data_json))
}