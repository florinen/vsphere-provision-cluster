
sed -i "/clusters/ {n;n;n;n;s/name: .*/name: ${env_name}/g}" $HOME/.kube/admin.conf
sed -i "/contexts/ {n;n;s/cluster: .*/cluster: ${env_name}/g}" $HOME/.kube/admin.conf
sed -i "/contexts/ {n;n;n;n;s/name: .*/name: kubernetes-admin@${env_name}/g}" $HOME/.kube/admin.conf
sed -i "s/current-context: .*/current-context: kubernetes-admin@${env_name}/g" $HOME/.kube/admin.conf
sed -i "/${env_name}/d" ~/.bash_profile

sudo rm -f $HOME/.kube/${env_name}
sudo mv $HOME/.kube/admin.conf $HOME/.kube/${env_name}

echo 'alias '${env_name}'="export KUBECONFIG=$HOME/.kube/'${env_name}' && kubectl config use-context kubernetes-admin@'${env_name}'"' >> ~/.bash_profile
