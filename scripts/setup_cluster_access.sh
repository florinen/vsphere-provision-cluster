
sed -i "/clusters/ {n;n;n;n;s/name: .*/name: ${env_name}/g}" $HOME/.kube/admin.conf
sed -i "/contexts/ {n;n;s/cluster: .*/cluster: ${env_name}/g}" $HOME/.kube/admin.conf
sed -i "/contexts/ {n;n;n;n;s/name: .*/name: kubernetes-admin@${env_name}/g}" $HOME/.kube/admin.conf
sed -i "s/current-context: .*/current-context: kubernetes-admin@${env_name}/g" $HOME/.kube/admin.conf

sudo rm -f $HOME/.kube/prod-env
sudo mv $HOME/.kube/admin.conf $HOME/.kube/prod-env