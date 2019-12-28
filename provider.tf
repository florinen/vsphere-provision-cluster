provider "vsphere" {
  version              = "~> 1.13"
  user                 = "${var.vsphere_connection["vsphere_user"]}"
  password             = "${var.vsphere_connection["vsphere_password"]}"
  vsphere_server       = "${var.vsphere_connection["vsphere_server"]}"
  allow_unverified_ssl = true
}

provider "external" {
  version = "~> 1.2"
}
provider "null" {
  version = "~> 2.1"
}
provider "template" {
  version = "~> 2.1"
}
data "vsphere_datacenter" "template_datacenter" {
  name = "${var.virtual_machine_template["datacenter"]}"
}
data "vsphere_datastore" "vm_datastore" {
  name          = "${var.virtual_machine_kubernetes_controller["datastore"]}"
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}
data "vsphere_compute_cluster" "vm_cluster" {
  name          = "${var.virtual_machine_kubernetes_controller["drs_cluster"]}"
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
  path = "${var.virtual_machine_template["folder"]}"
  type = "vm"
  tags = ["${vsphere_tag.environment.id}",
    "${vsphere_tag.region.id}",
  ]
  datacenter_id = "${data.vsphere_datacenter.template_datacenter.id}"
}
resource "vsphere_resource_pool" "vm_resource_pool" {
  name = "${var.virtual_machine_kubernetes_node["resource_pool"]}"
  tags = ["${vsphere_tag.environment.id}",
    "${vsphere_tag.region.id}",
  ]
  parent_resource_pool_id = "${data.vsphere_compute_cluster.vm_cluster.resource_pool_id}"
}
##  Files and Scripts  ##
data "template_file" "setup_cluster_access" {
  template = "${file("${path.module}/scripts/setup_cluster_access.sh")}"
  vars = {
    env_name = "${var.env_name}"
  }
}

data "template_file" "authorized_keys" {
  template = "${file("${path.module}/authorized_keys.tpl")}"
}
data "template_file" "calico_conf" {
  template = "${file("${path.module}/scripts/calico_conf.tpl")}"
}
data "template_file" "daemon" {
  template = "${file("${path.module}/scripts/daemon.tpl")}"
}
data "template_file" "kube_repo" {
  template = "${file("${path.module}/scripts/kubernetes.tpl")}"
}
data "template_file" "k8s_conf" {
  template = "${file("${path.module}/scripts/k8s_conf.tpl")}"
}

#++++++++++++++++++++
##  Tag Category Info   ##
#++++++++++++++++++++
resource "vsphere_tag_category" "environment" {
  name        = "${var.vsphere_tag_category}"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
    "Datacenter",
    "ResourcePool",
    "Folder",
  ]
}
resource "vsphere_tag_category" "region" {
  name        = "${var.vsphere_region_catergory}"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
    "Datacenter",
    "ResourcePool",
    "Folder",
  ]
}
resource "vsphere_tag_category" "master" {
  name        = "${var.vsphere_m_catergory}"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
    "Datacenter",
    "Folder",
  ]
}
resource "vsphere_tag_category" "worker" {
  name        = "${var.vsphere_w_catergory}"
  cardinality = "SINGLE"
  associable_types = [
    "VirtualMachine",
    "Datacenter",
    "Folder",
  ]
}

#+++++++++
## Tags Info ##
#+++++++++
resource "vsphere_tag" "environment" {
  name        = "${var.vsphere_tag_name}"
  category_id = "${vsphere_tag_category.environment.id}"
  description = "Environment type"
}
resource "vsphere_tag" "region" {
  name        = "${var.vsphere_region_name}"
  category_id = "${vsphere_tag_category.region.id}"
  description = "Location of the cluster"
}
resource "vsphere_tag" "master" {
  name        = "${var.vsphere_m_name}"
  category_id = "${vsphere_tag_category.master.id}"
  description = "Role Assignment"
}
resource "vsphere_tag" "worker" {
  name        = "${var.vsphere_w_name}"
  category_id = "${vsphere_tag_category.worker.id}"
  description = "Role Assignment"
}

