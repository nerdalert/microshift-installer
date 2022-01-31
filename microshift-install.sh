#!/bin/sh
set -e
set -o noglob

echo '- Installing cri-o container runtime...'
sudo dnf module enable -y cri-o:1.21
sudo dnf install -y cri-o cri-tools
sudo systemctl enable crio --now
echo -e "\xE2\x9C\x94 Done"

echo '- Installing Microshift packages...'
sudo dnf copr enable -y @redhat-et/microshift
sudo dnf install -y microshift firewalld
sudo systemctl enable microshift --now
echo -e "\xE2\x9C\x94 Done"

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
export KUBECONFIG=~/.kube/config
echo -e "\xE2\x9C\x94 Done"

export IP=$(hostname -I | awk '{print $1}')
echo -e "- Adding the following host entry to /etc/hosts if it doesn't exist: $(hostname) $IP"
if ! grep --quiet "$IP $hostname" /etc/hosts; then
  echo $IP $(hostname) | sudo tee -a /etc/hosts
fi
echo -e "\xE2\x9C\x94 Done\n"

echo "- Installation complete, view the pods with the following:"
echo -e "kubectl get pods --all-namespaces -o wide\n"
echo "- Once all of the microshift pods are up and running, test the deployment with:"
echo -e "kubectl apply -f https://k8s.io/examples/application/shell-demo.yaml  \n"
echo "See documentation at https://microshift.io/docs/home/"

