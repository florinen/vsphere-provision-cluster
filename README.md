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
source ./vsphere-set-env.sh terraform.tfvars
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

## Accessing and managing cluster from different host.

Clone repo:
``` 
	git clone git@github.com:florinen/vsphere-provision-cluster.git
	cd vsphere-provision-cluster
```
Copy terraform.tfvars file into this direcroy or point to it's location as well as all neccessary files:
```
	authorized_keys.tpl
	terraform.tfvars
```
Set the backend and init terraform:
```
	source ./vsphere-set-env.sh terraform.tfvars
```
Recreate resources with terraform:
```
	terraform taint null_resource.generate-sshkey
	terraform taint null_resource.ssh-keygen-delete-nodes
	terraform taint  null_resource.remove_ssh_keys
	
	terraform apply -var-file $DATAFILE --auto-approve
```
Get the pub key just created in above step and copy to all nodes, you can use older private key to access nodes or use older node to upload the pub key:
```
	cat ~/.ssh/id_rsa-prod.pub
	ssh -i ~/.ssh/<previous_node_priv_key> root@10.10.45.215
	vim ~/.ssh/authorized_keys
```
Make a new directory in user home directory. ONLY if does not exists:
```
	mkdir ~/.kube
```
Recreate resources using terraform taint cmd:
```
	terraform taint null_resource.cluster_access
	terraform taint null_resource.copy_kube_config
	
	terraform apply -var-file $DATAFILE --auto-approve
```
At the end you will need to source the bash_profile file or just simple logout and log back in:
```
	source ~/.bash_profile
```