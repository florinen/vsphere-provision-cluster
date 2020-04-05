## Copy Kube config to local machine. (Kube) folder must exist or create before copy.
resource "null_resource" "copy_kube_config" {
  provisioner "local-exec" {
    command = "scp -o ${var.accept_key} -i ${var.virtual_machine_kubernetes_controller["private_key"]} -r ${var.virtual_machine_template["connection_user"]}@${vsphere_virtual_machine.kubernetes_controller.0.default_ip_address}:/etc/kubernetes/admin.conf $HOME/.kube"
  } 
}
resource "null_resource" "cluster_access" {
    depends_on = [ null_resource.copy_kube_config ]
  provisioner "local-exec" {
    command = data.template_file.setup_cluster_access.rendered
  }
}


# resource "null_resource" "sleeping_subprocess" {
#   provisioner "local-exec" {
#       command = "sleep 10 & echo \"sleeping in PID $!\""
#   }
# }