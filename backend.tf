terraform {
  backend "s3" {
    bucket  = "kube.omegnet.com"
    key     = "vsphere/prod/terraform.tfstate"
    region  = "eu-west-1"
  }
}
