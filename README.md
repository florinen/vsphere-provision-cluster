# Provisioning Kubernetes cluster in vSphere 6.7

## Prerequisites:

Create one Centos 7 vm. After creation is finished, login and do the following:

 1. yum install -y open-vm-tools # or you can manualy install from vmware install disk

 2. yum install -y perl # without this package when VM starts network will be in disconnected state.

 3. you can create a user and generate ssh keys for the user if needed

 4. shutdown vm and convert it to Template

On the local machine where you run terraform script you must have "jq" installed. It is necessary for getting the kubernetes token and certhash that was generated when running ‘kubeadm init’. The 'kubeadm_init_info.sh' script also needs the "jq" program. These information will be needed when it comes to add new nodes in the cluster.

## Kubernetes Cluster with Flannel CNI
reference:
```
https://coreos.com/flannel/docs/latest/kubernetes.html
```
To create the clusrer run:
```
 terraform apply -var-file=terraform.tfvars
 ```
 If you would like to add or remove nodes from the cluster just modify the count number in the 'terraform.tfvars' then run the terraform apply again:
 ```
 terraform apply -var-file=terraform.tfvars
```
The assumption is that folder .Kube is created and aliases already setup
```
mkdir ~/.Kube
alias prod-env='export KUBECONFIG=$HOME/.kube/prod-env && \
                kubectl config use-context kubernetes-admin@prod-env'
```
When terraform is finished with cluster just run:
```
kubectl get nodes  # you may have to wait a few seconds for the nodes to be in a Ready State
``` 
Nodes will be added or removed in the order they were created.
After deletion of a node, remove the node that shows not ready state, run:
```
kubectl get nodes
kubectl delete node <node-name>
```

## Run Multiple masters in the cluster:
Will be comming soon! 
