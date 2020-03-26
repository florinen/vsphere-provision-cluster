# Provisioning Kubernetes cluster in vSphere 6.7

## Prerequisites:

Create one Centos 7 vm. After creation is finished, login and do the following:

 1. yum install -y open-vm-tools # or you can manualy install from vmware install disk

 2. yum install -y perl # without this package when VM starts network will be in disconnected state.

 3. you can create a user and generate ssh keys for the user if needed

 4. shutdown vm and convert it to Template

On the local machine where you run terraform script you must have "jq" installed. It is necessary for getting the kubernetes token and certhash that was generated when running ‘kubeadm init’. The 'kubeadm_init_info.sh' script also needs the "jq" program. These information will be needed when it comes to add new nodes in the cluster.

## Kubernetes Cluster with Calico CNI
reference:
```
https://docs.projectcalico.org/v3.11/introduction/
```
To create the clusrer run:
```
source ./vsphere-set-env.sh ../data/terraform.tfvars
terraform apply -var-file $DATAFILE
 ```
## Manual adding alias and creating Kubeconfig file if terraform is failling to do that.
```
mkdir ~/.Kube
scp root@<master_IP>:/etc/kubernetes/admin.conf ~/.kube/prod  ## edit 'prod' file with your settings
alias prod='export KUBECONFIG=$HOME/.kube/prod && \
                kubectl config use-context kubernetes-admin@prod'
```
## Using terraform 
```
terraform taint null_resource.cluster_access
terraform taint null_resource.copy_kube_config
terraform apply -var-file $DATAFILE --auto-approve
```
Above commands should copy admin.conf file and setup kubeconfig for you. If you are using bash profile, change that in the cluster_access.sh script. 
When terraform is finished with cluster just run:
```
kubectl get nodes  # you may have to wait a few seconds for the nodes to be in a Ready State
```
## To add or remove worker nodes. 
Change the count value in terraform.tfvars file for nodes, then:
```
terraform apply -var-file $DATAFILE 
````
Nodes will be added or removed in the order they were created.
After deletion of a node, remove the node that shows not ready state, run:
```
kubectl get nodes
kubectl delete node <node-name>
```
## To destroy the cluster
```
terraform destroy -var-file $DATAFILE 
```
## Run Multiple masters in the cluster:
Will be comming soon! 

## Trooubleshooting 

If 'token' missing from master, recreate token on master node. Token expires after 24h, this is default:
```
kubeadm token create --print-join-command >/tmp/kubeadm_init_output.txt
```
Exit master node and execute terraform apply again, this time new node should join the cluster. 
```
terraform apply -var-file $DATAFILE
```

## Last resort:

If above steps not helpful, do the next steps:
```
terraform taint 'vsphere_virtual_machine.kubernetes_controller[0]'
terraform taint 'null_resource.kubeadm_join[0]'
terraform taint 'null_resource.kubeadm_join[1]'
terraform apply -var-file $DATAFILE
```
This should recreate master node and rejoin the worker nodes to cluster.