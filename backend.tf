terraform {
  backend "consul" {
    address = "consul.omegnet.com"
    scheme  = "http"
    path    = "vsphere/node-creation"
  }
}

