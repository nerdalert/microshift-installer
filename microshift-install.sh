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

# Detect the OS and install cri-o
uname=$(uname -r)
if echo "$uname" | grep -Eq 'fc'; then
  echo "Fedora OS detected"
  echo '- Installing cri-o container runtime...'
  sudo dnf module enable -y cri-o:1.21
  sudo dnf install -y cri-o cri-tools
  sudo systemctl enable crio --now
  echo -e "\xE2\x9C\x94 Done"
  sleep 15
elif echo "$uname" | grep -Eq 'el'; then
  echo 'CentOS/RHEL OS detected'
  echo '- Installing cri-o container runtime...'
  sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8_Stream/devel:kubic:libcontainers:stable.repo
  sudo curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:1.21.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:1.21/CentOS_8_Stream/devel:kubic:libcontainers:stable:cri-o:1.21.repo
  sudo dnf install -y cri-o cri-tools
  sudo systemctl enable crio --now
  echo -e "\xE2\x9C\x94 Done"
else
  echo "No supported OS detected (requires CentOS or Fedora) exiting install.."
  exit
fi

echo '- Installing Microshift packages...'
sudo dnf copr enable -y @redhat-et/microshift
sudo dnf install -y microshift
sudo systemctl enable microshift --now
echo -e "\xE2\x9C\x94 Done"

# wait for the kubeconfig file to become available
echo "Wating for cri-o pods to initiate.."
count=1
kubeconf=/var/lib/microshift/resources/kubeadmin/kubeconfig
until sudo test -f $kubeconf; do
  if [ $count -gt 180 ]; then
    echo -e "\u274c kubeconfig not found in $kubeconf, there may be an issue with the installation"
    break
  fi
  count=$((count + 1))
  sleep 1
done

cricount=1
while ! sudo crictl ps | grep -q 'flannel'; do
  echo "sleeping"
  cricount=$((cricount + 1))
  echo $cricount
  if [ $cricount -gt 180 ]; then
    echo "timed out waiting on cri-o pods"
    break
  fi
  sleep 1
done

echo "- Storing kubeconfig in ~/.kube/config"
mkdir ~/.kube &>/dev/null
sudo cat /var/lib/microshift/resources/kubeadmin/kubeconfig >~/.kube/config
echo -e "\xE2\x9C\x94 Done"
echo "pods are initiating may take a couple of minutes depending on resources.."

export KUBECONFIG=~/.kube/config
kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=300s

echo "- Installation complete, view the pods with the following:"
echo "cmd -> export KUBECONFIG=~/.kube/config"
echo -e "cmd -> kubectl get pods --all-namespaces -o wide\n"
echo "- Once all of the microshift pods are up and running, test the deployment with:"
echo -e "cmd -> kubectl apply -f https://k8s.io/examples/application/shell-demo.yaml  \n"
