resource "null_resource" "generate-sshkey" {
  provisioner "local-exec" {
    command = "yes y | ssh-keygen -b 4096 -t rsa -C '${var.env_name}' -N '' -f ${var.virtual_machine_kubernetes_controller["private_key"]}"
  }
}

resource "null_resource" "ssh-keygen-delete" {
  provisioner "local-exec" {
    command = "ssh-keygen -R ${cidrhost(var.virtual_machine_kubernetes_controller["ip_address_network"], var.virtual_machine_kubernetes_controller["starting_hostnum"])}"
  }
}
resource "null_resource" "ssh-keygen-delete-nodes" {
  provisioner "local-exec" {
    command = "ssh-keygen -R ${cidrhost(var.virtual_machine_kubernetes_node["ip_address_network"], var.virtual_machine_kubernetes_node["starting_hostnum"])}"
  }
}
resource "null_resource" "remove_ssh_keys" {
  provisioner "local-exec" {
    when    = "destroy"
    command = "rm $HOME/.ssh/id_rsa-${var.env_name}*"
  }
}
