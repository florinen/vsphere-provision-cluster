resource "vsphere_virtual_machine" "kubernetes_nodes" {
  count            = "${var.virtual_machine_kubernetes_node["count"]}"
  name             = "${format("${var.deployment_environment}-${var.virtual_machine_kubernetes_node["prefix"]}-%03d", count.index + 1)}"
  resource_pool_id = "${vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.node_datastore.id}"
  folder           = "${vsphere_folder.folder.path}"
  num_cpus         = "${var.virtual_machine_kubernetes_node["num_cpus"]}"
  memory           = "${var.virtual_machine_kubernetes_node["memory"]}"
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type        = "${data.vsphere_virtual_machine.template.scsi_type}"
  enable_disk_uuid = "true"
  annotation       = "Managed by Terraform"
  tags             = ["${vsphere_tag.environment.id}",
                      "${vsphere_tag.region.id}",
                      "${vsphere_tag.worker.id}",
                      ]
  network_interface {
    network_id   = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.deployment_environment}-${var.virtual_machine_kubernetes_node["prefix"]}"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      timeout = "20"
      linux_options {
        host_name = "${format("${var.deployment_environment}-${var.virtual_machine_kubernetes_node["prefix"]}-%03d", count.index + 1)}"
        domain    = "${var.virtual_machine_kubernetes_node["domain"]}"
      }

      network_interface {
        ipv4_address = "${cidrhost(var.virtual_machine_kubernetes_node["ip_address_network"], var.virtual_machine_kubernetes_node["starting_hostnum"] + count.index)}"
        ipv4_netmask = "${element(split("/", var.virtual_machine_kubernetes_node["ip_address_network"]), 1)}"
      }

      ipv4_gateway    = "${var.virtual_machine_kubernetes_node["gateway"]}"
      dns_server_list = ["${var.virtual_machine_kubernetes_node["dns_server"]}"]

    }
  }

  provisioner "file" {
    source      = "${var.virtual_machine_kubernetes_controller["public_key"]}"
    destination = "/tmp/authorized_keys"

    connection {
      host     = "${element(self.*.default_ip_address, count.index)}"
      type     = "${var.virtual_machine_template["connection_type"]}"
      user     = "${var.virtual_machine_template["connection_user"]}"
      password = "${var.virtual_machine_template["connection_password"]}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh/",
      "chmod 700 /root/.ssh",
      "mv /tmp/authorized_keys $HOME/.ssh/authorized_keys",
      "tee -a $HOME/.ssh/authorized_keys <<EOF",
      "${data.template_file.authorized_keys.rendered}",
      "EOF", 
      "chmod 600 $HOME/.ssh/authorized_keys",
      "sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "service sshd restart"
    ]
    connection {
      host     = "${element(self.*.default_ip_address, count.index)}"
      type     = "${var.virtual_machine_template["connection_type"]}"
      user     = "${var.virtual_machine_template["connection_user"]}"
      password = "${var.virtual_machine_template["connection_password"]}"
    }
  }
  provisioner "remote-exec" {

    inline = [
    ## Disable swap  
      "swapoff -a",
      "sudo sed -i '/swap/d' /etc/fstab",
      "systemctl disable firewalld",
      "systemctl stop firewalld",
      "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config",
      "setenforce 0",
      "modprobe br_netfilter",
    
    ## Install some packages
      "yum install -y vim nfs-utils jq vim unzip wget",
    
      ## Install Docker
      "yum install -y yum-utils device-mapper-persistent-data lvm2 epel-release",
      "yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
      "yum update -y && yum install docker-ce-${var.d_version} -y",
      "mkdir /etc/docker",
      "tee  /etc/docker/daemon.json <<EOF",
      "${data.template_file.daemon.rendered}",
      "EOF", 
      "sudo mkdir -p /etc/systemd/system/docker.service.d",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart docker",
      "sudo systemctl enable docker",

    ]
    connection {
      host        = "${element(self.*.default_ip_address, count.index)}"
      type        = "${var.virtual_machine_template["connection_type"]}"
      user        = "${var.virtual_machine_template["connection_user"]}"
      private_key = "${file("${var.virtual_machine_kubernetes_controller["private_key"]}")}"
    }
  }

  provisioner "remote-exec" {
    inline = [ 
          "sudo echo \"${data.template_file.calico_conf.rendered}\" > /etc/NetworkManager/conf.d/calico.conf",
          "sudo echo \"${data.template_file.kube_repo.rendered}\" > /etc/yum.repos.d/kubernetes.repo"
    ]
    connection {
      host        = "${element(self.*.default_ip_address, count.index)}"
      type        = "${var.virtual_machine_template["connection_type"]}"
      user        = "${var.virtual_machine_template["connection_user"]}"
      private_key = "${file("${var.virtual_machine_kubernetes_controller["private_key"]}")}"
    }
  }
   
  provisioner "remote-exec" {
    inline = [
    ## Mount NFS
      "sudo mkdir /nfs/shares -p",
      "sudo echo '${var.nfs_server}:/mnt/Storage/Kube-data  /nfs/shares  nfs       rw,sync,hard,intr     0 0' >> /etc/fstab",
    
    ## Install kubernetes components  
      "sudo yum install -y kubelet-${var.k_version} kubeadm-${var.k_version} kubectl-${var.k_version} openssl --disableexcludes=kubernetes",
      "systemctl enable --now kubelet",     
      "sudo echo \"${data.template_file.k8s_conf.rendered}\" > /etc/sysctl.d/k8s.conf",
      "sudo sysctl --system",
      "sudo mount -av",

    ]
    connection {
      host        = "${element(self.*.default_ip_address, count.index)}"
      type        = "${var.virtual_machine_template["connection_type"]}"
      user        = "${var.virtual_machine_template["connection_user"]}"
      private_key = "${file("${var.virtual_machine_kubernetes_controller["private_key"]}")}"
    }
  }
}

## Join Nodes to cluster
resource "null_resource" "kubeadm_join" {
  count = "${var.virtual_machine_kubernetes_node["count"]}"
  provisioner "remote-exec" {
    inline = [
      "kubeadm join --node-name=$HOSTNAME --token ${data.external.kubeadm-init-info.result.token} ${vsphere_virtual_machine.kubernetes_controller.0.default_ip_address}:6443 --discovery-token-ca-cert-hash sha256:${data.external.kubeadm-init-info.result.certhash}",
    ]
    connection {
      host        = "${element(vsphere_virtual_machine.kubernetes_nodes.*.default_ip_address, count.index)}"
      type        = "${var.virtual_machine_template["connection_type"]}"
      user        = "${var.virtual_machine_template["connection_user"]}"
      private_key = "${file("${var.virtual_machine_kubernetes_controller["private_key"]}")}"

    }
  }
}