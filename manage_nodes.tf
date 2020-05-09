## Sleep Time is need it for the nodes to become Ready/NotReady otherwise manage_nodes may fail..!  

resource "null_resource" "sleeping_subprocess" {
  depends_on = [null_resource.kubeadm_join]
  triggers = {
    cluster_instance_ids = "${join(",", vsphere_virtual_machine.kubernetes_nodes.*.id)}"
  }
  provisioner "local-exec" {
    command = "sleep 50 & echo \"sleeping in PID $!\""
  }
}

resource "null_resource" "manage_nodes" {
  depends_on = [null_resource.sleeping_subprocess]

  triggers = {
    build_number = "${timestamp()}"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
      YELLOW=`tput setaf 3`
      GREEN=`tput setaf 2`
      MAGENTA=`tput setaf 5`
      RESET=`tput sgr0`

      source update.sh
      reload
      NODE_ROLE=$(kubectl get nodes | grep none | awk '{print $1}')
      REMOVE_NODE=$(kubectl get nodes | grep NotReady | awk '{print $1}')

      if [[ ! -z  "$NODE_ROLE"  ]]; then
         echo -e "$GREEN Asigned Roles to Nodes $RESET"
         for n in `echo $NODE_ROLE`; do kubectl label node $n node-role.kubernetes.io/worker=worker --overwrite; done 
       else
        echo "===>$YELLOW Nothing to label..$MAGENTA!! $RESET<==="
      fi
      if [[ ! -z "$REMOVE_NODE"  ]];then
         echo -e "$GREEN Removed Worker Nodes after Destroy $RESET" 
         for n in `echo $REMOVE_NODE`; do kubectl delete node $n; done
       else
        echo "===>$YELLOW Nothing to delete..$MAGENTA!! $RESET<==="
      fi
      EOF
  }

}
