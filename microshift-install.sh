# Install script for https://github.com/redhat-et/microshift
# Can be installed using: 
# curl -sfL https://raw.githubusercontent.com/nerdalert/microshift-installer/main/microshift-install.sh |  sh -s -
#!/bin/sh
set -e
set -o noglob

# If the node does not have a FQDN
export IP=$(hostname -I | awk '{print $1}')
echo -e "- Adding the following host entry to /etc/hosts if it doesn't exist: $(hostname) $IP"
if ! grep --quiet "$IP $hostname" /etc/hosts; then
  echo $IP $(hostname) | sudo tee -a /etc/hosts
fi
echo -e "\xE2\x9C\x94 Done\n"

echo '- Installing pre-requisites...'
sudo dnf install -y podman
echo -e "\xE2\x9C\x94 Done"
sleep 15

echo '- Installing cri-o container runtime...'
sudo dnf module enable -y cri-o:1.21
sudo dnf install -y cri-o cri-tools
sudo systemctl enable crio --now
echo -e "\xE2\x9C\x94 Done"
sleep 30

echo '- Installing Microshift packages...'
sudo dnf copr enable -y @redhat-et/microshift
sudo dnf install -y microshift firewalld
sleep 30
sudo systemctl enable microshift --now
echo -e "\xE2\x9C\x94 Done"

# wait up to 30 seconds for the kubeconfig file to become available
count=1
kubeconf=/var/lib/microshift/resources/kubeadmin/kubeconfig
until sudo test -f $kubeconf;do
  if [ $count -gt 30 ]; then
      echo -e "\u274c kubeconfig not found in $kubeconf, there may be an issue with the installation"
    break
  fi
  count=$((count+1))
  sleep 1
done

echo "- Storing kubeconfig in ~/.kube/config"
mkdir ~/.kube  &> /dev/null
sudo cat /var/lib/microshift/resources/kubeadmin/kubeconfig > ~/.kube/config
echo -e "\xE2\x9C\x94 Done"

echo "- Installation complete, view the pods with the following:"
echo "cmd -> export KUBECONFIG=~/.kube/config"
echo -e "cmd -> kubectl get pods --all-namespaces -o wide\n"
echo "- Once all of the microshift pods are up and running, test the deployment with:"
echo -e "cmd -> kubectl apply -f https://k8s.io/examples/application/shell-demo.yaml  \n"
echo "See documentation at https://microshift.io/docs/home/"
