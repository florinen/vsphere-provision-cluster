
resource "vsphere_virtual_machine" "kubernetes_controller" {
  count            = "${var.virtual_machine_kubernetes_controller["count"]}"
  name             = "${format("${var.virtual_machine_kubernetes_controller["name"]}-%03d", count.index + 1)}"
  resource_pool_id = "${vsphere_resource_pool.vm_resource_pool.id}"
  datastore_id     = "${data.vsphere_datastore.vm_datastore.id}"
  folder           = "${vsphere_folder.folder.path}"
  num_cpus         = "${var.virtual_machine_kubernetes_controller["num_cpus"]}"
  memory           = "${var.virtual_machine_kubernetes_controller["memory"]}"
  guest_id         = "${data.vsphere_virtual_machine.template.guest_id}"
  scsi_type        = "${data.vsphere_virtual_machine.template.scsi_type}"
  enable_disk_uuid = "true"
  annotation       = "Managed by Terraform"
  tags             = ["${vsphere_tag.environment.id}",
                      "${vsphere_tag.region.id}",
                      "${vsphere_tag.master.id}",
                      ]
  network_interface {
    network_id   = "${data.vsphere_network.vm_network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "${var.virtual_machine_kubernetes_controller["name"]}"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks.0.thin_provisioned}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks.0.eagerly_scrub}"
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      timeout = "20"
      linux_options {
        host_name = "${format("${var.virtual_machine_kubernetes_controller["name"]}-%03d", count.index + 1)}"
        domain    = "${var.virtual_machine_kubernetes_controller["domain"]}"
      }

      network_interface {
        ipv4_address = "${cidrhost(var.virtual_machine_kubernetes_controller["ip_address_network"], var.virtual_machine_kubernetes_controller["starting_hostnum"] + count.index)}"
        ipv4_netmask = "${element(split("/", var.virtual_machine_kubernetes_controller["ip_address_network"]), 1)}"
      }

      ipv4_gateway    = "${var.virtual_machine_kubernetes_controller["gateway"]}"
      dns_server_list = ["${var.virtual_machine_kubernetes_controller["dns_server"]}"]

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
      "mv /tmp/authorized_keys /root/.ssh/authorized_keys",
      "chmod 600 /root/.ssh/authorized_keys",
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


  provisioner "file" {
    source      = "${var.virtual_machine_kubernetes_controller["my_ssh_keys"]}"
    destination = "/tmp/my_ssh_keys"

    connection {
      host        = "${element(self.*.default_ip_address, count.index)}"
      type        = "${var.virtual_machine_template["connection_type"]}"
      user        = "${var.virtual_machine_template["connection_user"]}"
      private_key = "${file("${var.virtual_machine_kubernetes_controller["private_key"]}")}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "cat /tmp/my_ssh_keys >> $HOME/.ssh/authorized_keys",
      "rm -f '/tmp/my_ssh_keys'",
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
      "swapoff -a",
      "sudo sed -i '/swap/d' /etc/fstab",
      "systemctl disable firewalld",
      "systemctl stop firewalld",
      "sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config",
      "setenforce 0",
      ## Install Docker
      "yum install -y yum-utils device-mapper-persistent-data lvm2 epel-release",
      "yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo",
      "yum update -y && yum install docker-ce-${var.d_version} -y",
      "mkdir /etc/docker",

    ]

    connection {
      host        = "${element(self.*.default_ip_address, count.index)}"
      type        = "${var.virtual_machine_template["connection_type"]}"
      user        = "${var.virtual_machine_template["connection_user"]}"
      private_key = "${file("${var.virtual_machine_kubernetes_controller["private_key"]}")}"
    }
  }

  provisioner "file" {
    source      = "./scripts/daemon.json"
    destination = "/etc/docker/daemon.json"

    connection {
      host        = "${element(self.*.default_ip_address, count.index)}"
      type        = "${var.virtual_machine_template["connection_type"]}"
      user        = "${var.virtual_machine_template["connection_user"]}"
      private_key = "${file("${var.virtual_machine_kubernetes_controller["private_key"]}")}"
    }
  }
  provisioner "remote-exec" {
    inline = [
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

  provisioner "file" {
    source      = "./scripts/kubernetes.repo"
    destination = "/etc/yum.repos.d/kubernetes.repo"

    connection {
      host        = "${element(self.*.default_ip_address, count.index)}"
      type        = "${var.virtual_machine_template["connection_type"]}"
      user        = "${var.virtual_machine_template["connection_user"]}"
      private_key = "${file("${var.virtual_machine_kubernetes_controller["private_key"]}")}"
    }
  }
  provisioner "file" {
    source      = "./scripts/kubeadm_init_info.sh"
    destination = "/tmp/kubeadm_init_info.sh"

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
      #"sudo echo '${var.nfs_server} /nfs/shares  nfs       rw,sync,hard,intr       0 0' >> /etc/fstab",
  ## Install pakages    
      "yum install -y  jq vim unzip wget",
      "chmod +x /tmp/*sh",
      "sudo yum install -y nfs-utils kubelet-${var.k_version} kubeadm-${var.k_version} kubectl-${var.k_version} openssl --disableexcludes=kubernetes",
      "sudo systemctl enable kubelet && sudo systemctl start kubelet",
      "sudo cat <<EOF >  /etc/sysctl.d/k8s.conf \nnet.bridge.bridge-nf-call-ip6tables = 1 \nnet.bridge.bridge-nf-call-iptables = 1",
      "EOF",
      "sudo sysctl --system",
      #"sudo mount -av",
      "IPADDRESS=$(ip address show dev  ens192 | grep 'inet ' | awk '{print $2}' | cut -d '/' -f1)",
      "echo '--> pull kubeadm images <--'",
      "kubeadm config images pull",
      "echo '--> run 'kubeadm init' <--'",
      "kubeadm init --apiserver-advertise-address=$IPADDRESS --pod-network-cidr=10.244.0.0/16 > /tmp/kubeadm_init_output.txt",
      "echo '--> setup $HOME/.kube/config <--'",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "echo '--> install flannel <--'",
      "sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml",
      "tail -n2 /tmp/kubeadm_init_output.txt | head -n 1",

    ]
    connection {
      host        = "${element(self.*.default_ip_address, count.index)}"
      type        = "${var.virtual_machine_template["connection_type"]}"
      user        = "${var.virtual_machine_template["connection_user"]}"
      private_key = "${file("${var.virtual_machine_kubernetes_controller["private_key"]}")}"
    }
  }
}
data "external" "kubeadm-init-info" {
  program = ["bash", "${path.module}/scripts/kubeadm_init_info.sh"]
  query = {
    ip_address  = "${vsphere_virtual_machine.kubernetes_controller.0.default_ip_address}"
    private_key = "${var.virtual_machine_kubernetes_controller["private_key"]}"
  }
}





