# Terraform Proxmox

This workflow deploys a packer image bootstrapped using cloudinit. This worlflow requires [packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli) to be installed

##### Dependancies
- loganmancuso_infrastructure/proxmox/datacenter-infrastructure>
- loganmancuso_infrastructure/proxmox/global-secrets>

## Deploy
to deploy this workflow link the environment tfvars folder to the root directory. 
```bash
  ln -s env/{packer_image}/* .
  tofu init .
  tofu plan
  tofu apply
```

#### Special Thanks:
This [project](https://github.com/bpg/terraform-provider-proxmox/tree/main) has been a huge foundation on which to build this automation, please consider sponsoring [Pavel Boldyrev](https://github.com/bpg)