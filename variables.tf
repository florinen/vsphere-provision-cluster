variable "vsphere_connection" {
  type        = "map"
  description = "Configuration details for connecting to vsphere"

  default = {
    # vsphere login account. defaults to administrator@vsphere.local account
    vsphere_user = ""
    # vsphere account password. empty by default
    vsphere_password = ""
    # vsphere server, defaults to localhost
    vsphere_server = ""
    #allow_unverified_ssl    = "true"
  }
}

variable "virtual_machine_template" {
  type        = "map"
  description = "Configuration details for virtual machine template"

  default = {
    # name of the template to deploy from. empty by default
    name = ""
    # default connection_type to SSH
    connection_type = ""
    # username to connect to deployed virtual machines. defaults to "root"
    connection_user = ""
    # default password to initially connect to deployed virtual machines. empty by default
    connection_password = ""
    # vsphere datacenter that the template is located in. empty by default
    datacenter  = ""
    drs_cluster = ""
    folder      = ""
  }
}

variable "virtual_machine_kubernetes_controller" {
  type        = "map"
  description = "Configuration details for kubernetes_controller virtual machine"

  default = {
    count = "1"
    # name of the virtual machine to be deployed. defaults to "kubernetes-controller"
    name = ""
    # name of the datastore to deploy kubernetes_controller to. defaults to "datastore1"
    datastore = ""
    # name of network to deploy kubernetes_controller to. defaults to "VM Network"
    network = ""
    # ip address to be assigned to kubernetes_controller. empty by default
    ip_address_network = ""
    # netmask assigned to kubernetes_controller. defaults to "24"
    netmask = ""
    # dns server assigned to kubernetes_controller
    dns_server       = ""
    starting_hostnum = ""
    # default gateway to be assigned to kubernetes_controller. empty by default
    gateway = ""
    # resource pool to deploy kubernetes_controller to. empty by default
    resource_pool = ""
    # private key to be used for SSH connections - this will be generated/overwritten on a terraform apply
    private_key = ""
    # public key to be copied to virtual machine
    public_key = ""
    # My public key
    my_ssh_keys = ""
    # number of vcpu assigned to kubernetes_controller. default is 2
    num_cpus = 2
    # amount of memory assigned to kubernetes_controller. default is 4096 (4GB)
    memory = ""
    domain = ""
    label  = ""
    hosts  = ""
  }
}

variable "virtual_machine_kubernetes_node" {
  type        = "map"
  description = "Configuration details for kubernetes_controller virtual machine"

  default = {
    # number of kuvernetes node virtual machines to deploy. defaults to 1
    count = 1
    # prefix of the virtual machine to be deployed. defaults to "kubernetes-node"
    name_prefix = "kubernetes-node-"
    # name of the datastore to deploy kubernetes_node virtual machines to. defaults to "datastore1"
    datastore = ""
    # name of network to deploy kubernetes_node virtual machines to. defaults to "VM Network"
    network = ""
    # the ip address network that will be used to determine the ip address assigned to kubernetes_node virtual machines. defaults to "192.168.100.0/24"
    ip_address_network = ""
    # the start_hostnum should be set to the 4th octet of the first kubernetes_node virtual machine. this will be combined with the count.index to determine the 4th octet of the ip address for each kuberenetes_node virtual machine. defaults to "101"
    starting_hostnum = ""
    # dns server assigned to kubernetes_node virtual machines. defaults to "8.8.8.8"
    dns_server = ""
    # default gateway to be assigned to kubernetes_node virtual machines. empty by default
    gateway = ""
    # resource pool to deploy kubernetes_node virtual machines to. empty by default
    resource_pool = ""
    # number of vcpu assigned to kubernetes_node virtual machines. default is 2
    num_cpus = 2
    # amount of memory assigned to kubernetes_node virtual machines. default is 4096 (4GB)
    memory = ""
    domain = ""
    label  = ""
    hosts  = ""
  }
}
variable "Flannel" {
  description = "Install Flannel Network"
  default     =[ "echo '--> Flannel network is currently installed <--'",
                 "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
                 ] 
}
variable "flannel_cidr" {
  description = "CIDR IP address"
  default     =  "10.244.0.0/16"
}


variable "k_version" {
  description = "Kebernetes version"
}
variable "d_version" {
  description = "Docker version"
}
variable "nfs_server" {
  description = "NFS share server"
}

## Tagging Info
variable "vsphere_tag_category" {
  description = "vSphere Tag Catagory Details"
}
variable "vsphere_tag_name" {
  description = "vSphere Tag Details"
}
variable "vsphere_region_name" {
  description = "vSphere Region Details"
}
variable "vsphere_region_catergory" {
  description = "vSphere Region Category Details"
}
variable "vsphere_m_catergory" {
  default = "vSphere Master Details"
}
variable "vsphere_w_catergory" {
  default = "vSphere Worker Details"
}
variable "vsphere_m_name" {
  default = "vSphere Master Detail"
}
variable "vsphere_w_name" {
  default = "vSphere Worker Detail"
}






