terraform {
  backend "s3" {
    bucket  = "kube.omegnet.com"
    key     = "vsphere/dev/terraform.tfstate"
    region  = "eu-west-1"
  }
}
