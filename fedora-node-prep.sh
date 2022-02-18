# prep a base Fedora node to deploy microshift or k8s on for a dev environment
# run with: 
# curl -sfL https://raw.githubusercontent.com/nerdalert/microshift-installer/main/fedora-node-prep.sh |  sh -s -
#!/bin/sh
set -e 
set -o noglob 


# CentOS
# sudo dnf -y install epel-release
# sudo dnf -y install snapd
# sudo systemctl enable --now snapd.socket

# Fedora
echo "Installing Apps"
sudo dnf -y install vim wget snapd git python3-pip tcpdump net-tools make dnf-plugins-core autofs vim curl wget snapd kernel-modules squashfuse upx unzip nc bind-utils telnet nmap iperf3 dbus-tools

echo "Installing yq"
sudo snap install yq || > /dev/null
sleep 5
echo "Installing yq retry”
sudo snap install yq || > /dev/null

#echo "Installing GO"
wget https://go.dev/dl/go1.17.7.linux-amd64.tar.gz
sudo rm -rf /usr/local/go || > /dev/null
sudo tar -C /usr/local -xzf go1.17.7.linux-amd64.tar.gz

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
# sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
# sudo dnf install docker-ce docker-ce-cli containerd.io
# sudo systemctl start docker
# sudo systemctl enable docker
# sudo groupadd docker
# sudo usermod -aG docker $USER

echo "Deleting /etc/machine-id"
sudo rm /etc/machine-id
sudo dbus-uuidgen --ensure=/etc/machine-id

echo "Change your IP with: "
echo "nmcli con show -a "
echo "sudo nmcli connection modify d313821d-3dd0-3298-a117-0d8f1a7ee609 IPv4.address 192.168.1.93/24"

echo "sudo hostnamectl set-hostname"
