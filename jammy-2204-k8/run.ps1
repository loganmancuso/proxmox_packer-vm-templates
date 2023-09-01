packer validate -var-file="..\secret.pkrvars.hcl" .\main.pkr.hcl
if($?) {
  packer build -var-file="..\secret.pkrvars.hcl" .\main.pkr.hcl 
}