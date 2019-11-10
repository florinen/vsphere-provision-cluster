provider "vsphere" {
  version        = "~> 1.13"
  user           = "${var.vsphere_connection["vsphere_user"]}"
  password       = "${var.vsphere_connection["vsphere_password"]}"
  vsphere_server = "${var.vsphere_connection["vsphere_server"]}"
  allow_unverified_ssl = true
}
provider "external" {
  version  = "~> 1.2"
}
provider "null" {
  version  = "~> 2.1"
}


data "vsphere_datacenter" "template_datacenter" {
  name = "${var.virtual_machine_template["datacenter"]}"
}
data "vsphere_datastore" "vm_datastore" {
  name          = "${var.virtual_machine_kubernetes_controller["datastore"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}
data "vsphere_compute_cluster" "vm_cluster" {
  name = "${var.virtual_machine_kubernetes_controller["drs_cluster"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}
data "vsphere_network" "vm_network" {
  name          = "${var.virtual_machine_kubernetes_controller["network"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}

## NODES ##
data "vsphere_datastore" "node_datastore" {
  name          = "${var.virtual_machine_kubernetes_node["datastore"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
} 

data "vsphere_virtual_machine" "template" {
  name          = "${var.virtual_machine_template["name"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}
resource "vsphere_folder" "folder" {
  path   = "${var.virtual_machine_template["folder"]}"
  type   = "vm"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}
resource "vsphere_resource_pool" "vm_resource_pool" {
  name          = "${var.virtual_machine_kubernetes_node["resource_pool"]}"
  parent_resource_pool_id = "${data.vsphere_compute_cluster.vm_cluster.resource_pool_id}"
}