# Terraform Proxmox

This workflow deploys a packer image bootstrapped using cloudinit. This worlflow requires packer to be installed

## Usage
to deploy this workflow link the environment tfvars folder to the root directory. 
```
  ln -s env/{packer_image}/main.tf
  ln -s env/{packer_image}/terraform.tfvars

  tofu init .
  tofu plan
  tofu apply
```