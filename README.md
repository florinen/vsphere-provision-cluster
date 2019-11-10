# Provisioning Kubernetes cluster in vSphere 

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
