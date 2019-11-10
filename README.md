# Provisioning Kubernetes cluster in vSphere 6.7

## Prerequisites:

Create one Centos 7 vm After creation is finished, login and do the following:

 1. yum install -y open-vm-tools # or you can manualy install from vmware install disk

 2. yum install -y perl # without this package when VM starts network will be in disconnected state.

 3. you can create a user and generate ssh keys for the user if needed

 4. shutdown vm and convert it to Template

On the local machine where you run terraform script you must have "jq" installed. It is necessary for getting the kubernetes token and certhash that was generated when running ‘kubeadm init’. These two pieces of information will be needed when it comes to add new nodes in the cluster. The 'kubeadm_init_info.sh' script needs the jq program, so we need to make sure it is installed on the machine running the terraform code.

To create the clusrer run:
```
 terraform apply -var-file=terraform.tfvars
 ```
 If you would like to add or remove nodes from the cluster just modify the count number in the 'terraform.tfvars' then run the terraform apply again:
 ```
 terraform apply -var-file=terraform.tfvars
```
Nodes will be added or removed in the order they were created.
After deletion of a node, remove the node that shows not ready state, run:
```
kubectl get nodes
kubectl delete node <node-name>
```

## Run Multiple masters in the cluster:
Will be comming soon! 
