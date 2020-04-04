terraform {
  backend "s3" {
    bucket  = "kube.omegnet.com"
    key     = "vsphere/qa/qa-terraform.tfstate"
    region  = "eu-west-1"
  }
}
