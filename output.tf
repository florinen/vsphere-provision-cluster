output "controller_ip" { 
   value = "${vsphere_virtual_machine.kubernetes_controller.*.default_ip_address}" 
}
output "node_ips" {
   value = "${vsphere_virtual_machine.kubernetes_nodes.*.default_ip_address}"
}
output "controller_vm-name" {
   value = "${vsphere_virtual_machine.kubernetes_controller.*.name}"
}
output "node_vm-name" {
   value = "${vsphere_virtual_machine.kubernetes_nodes.*.name}"
}
output "kubeadm-init-info" {
   value = "${data.external.kubeadm-init-info.result}"
}

