# the following script will remove the flannel CNI plugin and its residue components

# Remove flannel components such as Daemonsets, deployments, and services using the official manifest
# This needs to run first on the master node
echo "modifying cluster manifest to be CNI neutral"

kops replace -f ~/CNIyamls/nocni.yaml 
kops update cluster --name primary.cnimigration.com --yes
# Remove flannel components such as Daemonsets, deployments, and services using the official manifest
# This needs to run first on the master node
truncate -s 0 ~/.ssh/known_hosts
ssh -i  ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "kubectl delete -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
truncate -s 0 ~/.ssh/known_hosts
kops validate cluster | tail -n 6| head -n 4| awk -F " " '{print $1}' > nodes.txt 

for i in $(cat nodes.txt); do ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@$i " sudo rm -rf /etc/cni/net.d/*"; done 

for i in node.txt; do ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@$line "sudo rm -rf /etc/cni/net.d/*"; done
for i in node.txt; do ssh -i ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@$line "ip link delete flannel.1"; done
#rolling update the cluster once flannel is removed
kops rolling-update cluster --cloudonly --force --master-interval=1s --node-interval=1s --yes
sleep 20m
echo "Starting the installation of Calico CNI plugin"
#install calico
#under the CNIyamls directory, in the official calico config yaml obtained from  https://docs.projectcalico.org/manifests/calico.yaml, remove the comment string '#' from the CALICO_IPV4_POOLCIDR lines
#the CIDR will be replaced with the cluster CIDR before applying the calico manifest
#the critical calico system nodes will not start if the cluster CIDR is not initialized
#100.96.0.0/11 is the cluster CIDR
#copy modified yaml to the home directory on master node
scp CNIyamls/calico_modified.yaml ubuntu@api.primary.cnimigration.com:/home/ubuntu/calico.yaml
#apply modified manifest file
ssh -i  ~/.ssh/id_rsa -oStrictHostKeyChecking=no ubuntu@api.primary.cnimigration.com "kubectl apply -f calico.yaml"
sleep 2m
kops validate cluster


