# prep a base Fedora node to deploy microshift or k8s on for a dev environment
#!/bin/sh
set -e 
set -o noglob 


# CentOS
sudo dnf -y install epel-release
sudo dnf -y install snapd
sudo systemctl enable --now snapd.socket

# Fedora
echo "Installing Apps"
sudo dnf -y install vim wget snapd git python3-pip tcpdump net-tools make autofs vim curl wget snapd kernel-modules squashfuse upx unzip nc kernel-modules bind-utils telnet nmap iperf3

echo "Installing yq"
sudo snap install yq
sleep 5
echo "Installing yq retry”
sudo snap install yq

#echo "Installing GO"
cd /usr/local
sudo wget https://go.dev/dl/go1.17.7.linux-amd64.tar.gz
sudo tar -xvzf go1.17.7.linux-amd64.tar.gz go
cd ~/

echo "Installing Kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

echo "Stopping Firewalld"
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl status firewalld

echo "Disabling SELinux"
sudo sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
getenforce
sudo setenforce 0
getenforce

# Enabble IP forwarding
sudo sysctl net.ipv4.ip_forward=1

# Install cri-tools crictl 
VERSION="v1.23.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz

# echo "Installing Docker"
# sudo dnf -y install dnf-plugins-core
# sudo dnf -y install docker-ce docker-ce-cli containerd.io

echo "Deleting /etc/machine-id"
sudo rm /etc/machine-id
sudo dbus-uuidgen --ensure=/etc/machine-id
