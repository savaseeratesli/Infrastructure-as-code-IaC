#!/bin/bash

sudo su
sudo -i

echo "===================== Değişken tanımları yapılıyor =========================="

export MASTER_IP="192.168.68.50"
export WORKER_IP="192.168.68.51"
export NODE_NAME="k3s-master1"
export HOSTNAME_MASTER="master1"
export HOSTNAME_WORKER="worker1"
export MANAGE_IP="192.168.68.49"
export HOSTNAME_MANAGE="manage"

echo ${MASTER_IP}
echo ${WORKER_IP}
echo ${NODE_NAME}  
echo ${HOSTNAME_MASTER}
echo ${HOSTNAME_WORKER}
echo ${MANAGE_IP}
echo ${HOSTNAME_MANAGE}

echo "===================== Hosts ekleniyor =========================="

echo "${MASTER_IP} ${HOSTNAME_MASTER}" | sudo tee -a /etc/hosts
echo "${WORKER_IP} ${HOSTNAME_WORKER}" | sudo tee -a /etc/hosts
echo "${MANAGE_IP} ${HOSTNAME_MANAGE}" | sudo tee -a /etc/hosts

echo "===================== Sistem güncelleniyor =========================="
sudo dnf -y update

echo "===================== Firewalld kapatılıyor =========================="
sudo systemctl disable --now firewalld 

echo "===================== SSH ayarları yapılıyor =========================="
sudo -i sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo -i sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo -i systemctl enable --now sshd
sudo -i systemctl restart sshd

echo "===================== Hostname ayarlanıyor =========================="
sudo hostnamectl set-hostname ${HOSTNAME_MANAGE}

echo "===================== Kurulum dizini ayarlanıyor =========================="
sudo -i export PATH=$PATH:/usr/local/bin

# Root PATH fix 
if ! grep -q "/usr/local/bin" /root/.bashrc; then
  echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc
fi

echo "===================== Temel paketler kuruluyor =========================="

sudo dnf install -y \
  ca-certificates \
  curl \
  gnupg \
  wget \
  net-tools \
  nmap \
  openssh-server \
  openssl \
  git \
  cloud-utils-growpart
  
echo "===================== / filesystem Büyütülüyor =========================="

sudo growpart /dev/sda 2
sudo resize2fs /dev/sda2
  
echo "===================== Docker CE repo ekleniyor =========================="
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "===================== Docker kuruluyor =========================="
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker

echo "===================== Docker Compose kuruluyor =========================="
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "===================== Ansible kurulumu =========================="

sudo dnf install -y epel-release
sudo dnf makecache
sudo dnf install -y ansible-core

echo "===================== Gerekli kernel modülleri yükleniyor =========================="

sudo modprobe overlay
sudo modprobe br_netfilter
sudo modprobe ip_tables
sudo modprobe iptable_filter
sudo modprobe iptable_nat

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

cat <<EOF > /etc/sysctl.d/99-disable-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

sudo sysctl --system

echo "===================== K3S kurulumu =========================="

curl -sfL https://get.k3s.io | sh -s - server --node-ip=${MANAGE_IP} --bind-address=${MANAGE_IP} --advertise-address=${MANAGE_IP} --node-label role=manage

echo "K3s node durumu kontrol ediliyor..."
sleep 30


echo "===================== Helm kurulumu =========================="

#sudo -i 

curl -fsSL https://get.helm.sh/helm-v4.0.4-linux-amd64.tar.gz | sudo tar -xz
sudo mv ./linux-amd64/helm /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm

## Root PATH fix 
#if ! grep -q "/usr/local/bin" /root/.bashrc; then
#  echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc
#fi

#echo "===================== Docker imajı çalıştırılıyor =========================="
#sudo docker run -d -p 7000:80 --name vms-test savaseeratesli/vms-test:latest

echo "===================== Uygulamalar için Git Reposu çekiliyor =========================="
cd /root
git clone https://github.com/savaseeratesli/Infrastructure-as-code-IaC.git
sleep 5
echo "Downloaded"

echo "===================== Dosyalar ilgili dizinlere kopyalanıyor =========================="

sudo cp -r /root/Infrastructure-as-code-IaC/ComposeFiles /opt
sudo cp -r /root/Infrastructure-as-code-IaC/ComposeServices/*.service /etc/systemd/system/
echo "Copied"
sudo chmod +x /opt/ComposeFiles/concourse/iptables-modules.sh
echo "Authorized +x"

echo "===================== Servisler Enable yapılıyor =========================="

sudo systemctl enable concourse-compose.service
sudo systemctl enable nginx-compose.service
sudo systemctl enable portainer-compose.service
sudo systemctl enable prometheus-compose.service
sudo systemctl enable rancherui-compose.service
sudo systemctl enable semaphore-compose.service
sudo systemctl enable sonarqube-compose.service
#sudo systemctl enable iptables-modules.service

sudo systemctl daemon-reload

echo "===================== Servisler Start yapılıyor =========================="

#sudo systemctl start iptables-modules.service
#sleep 5
#echo "iptables-modules.service OK"
#sudo systemctl start concourse-compose.service
#sleep 5
#echo "concourse-compose.service OK"
#sudo systemctl start portainer-compose.service
#sleep 5
#echo "portainer-compose.service OK" 
sudo systemctl start rancherui-compose.service
sleep 5
echo "rancherui-compose.service OK" 

echo "===================== Concourse FLY Kuruluyor =========================="

#curl 'http://localhost:8080/api/v1/cli?arch=amd64&platform=linux' -o fly
#sudo chmod +x ./fly
#sudo mv ./fly /usr/local/bin/

## Root PATH fix 
#if ! grep -q "/usr/local/bin" /root/.bashrc; then
#  echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc
#fi

echo "===================== FLY Login =========================="

#/usr/local/bin/fly -t tutorial login -c http://localhost:8080 -u test -p test

echo "===================== Uygulamaların Çalışması Bekleniyor =========================="

SERVER_IP=$(ip -4 addr show eth1 | awk '/inet /{print $2}' | cut -d/ -f1)

#echo "http://${SERVER_IP}:8080/ --> concourseci"
#echo "==============================================="
#echo "https://${SERVER_IP}:9443/ --> portainerio"
#echo "==============================================="

echo "Rancher ayağa kalkması bekleniyor: https://${SERVER_IP}:8443/ "

while true; do
  STATUS_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" "https://${SERVER_IP}:8443/")

  if [ "$STATUS_CODE" -eq 200 ]; then
    echo "Rancher hazır (HTTP 200)"

    sudo docker logs rancher 2>&1 | \
      awk -F 'Bootstrap Password: ' '/Bootstrap Password:/ {print "Bootstrap Password: " $2}'

    break
  else
    echo "Henüz hazır değil (HTTP $STATUS_CODE). Tekrar denenecek..."
    sleep 10
  fi
done
echo "===================== Kurulum tamamlandı =========================="
