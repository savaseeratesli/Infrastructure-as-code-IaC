#!/bin/bash

set -e

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
sudo hostnamectl set-hostname test

echo "===================== Kurulum dizini ayarlanıyor =========================="
sudo -i export PATH=$PATH:/usr/local/bin

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
  git 
  
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

echo "===================== K3S kurulumu =========================="

sudo -i 

if ! command -v k3s &> /dev/null; then
  curl -sfL https://get.k3s.io | sh -
fi

echo "K3s node durumu kontrol ediliyor..."
sleep 30

# Root için kubectl kubeconfig ayarı
echo "Root için kubectl yapılandırılıyor..."

mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
chown root:root /root/.kube/config


echo "===================== Helm kurulumu =========================="

sudo -i 

curl -fsSL https://get.helm.sh/helm-v4.0.4-linux-amd64.tar.gz | sudo tar -xz
sudo mv linux-amd64/helm /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm

# Root PATH fix 
if ! grep -q "/usr/local/bin" /root/.bashrc; then
  echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc
fi

echo "===================== Docker imajı çalıştırılıyor =========================="
sudo docker run -d -p 7000:80 --name vms-test savaseeratesli/vms-test:latest

echo "===================== Uygulamalar için Git Reposu çekiliyor =========================="

sudo -i
git clone https://github.com/savaseeratesli/Infrastructure-as-code-IaC.git

echo "===================== Dosyalar ilgili dizinlere kopyalanıyor =========================="

sudo -i
sudo cp -r /root/Infrastructure-as-code-IaC/ComposeFiles /opt
sudo cp -r /root/Infrastructure-as-code-IaC/ComposeServices/*.service /etc/systemd/system/

echo "===================== Servisler Enable yapılıyor =========================="

sudo systemctl enable concourse-compose.service
sudo systemctl enable nginx-compose.service
sudo systemctl enable portainer-compose.service
sudo systemctl enable prometheus-compose.service
sudo systemctl enable rancherui-compose.service
sudo systemctl enable semaphore-compose.service
sudo systemctl enable sonarqube-compose.service

sudo systemctl daemon-reload

echo "===================== Kurulum tamamlandı =========================="
