#!/bin/bash

set -e

echo "===================== Sistem güncelleniyor =========================="
sudo dnf -y update

echo "===================== Firewalld kapatılıyor =========================="
sudo systemctl disable --now firewalld || true

echo "===================== Temel paketler kuruluyor =========================="
sudo dnf install -y \
  ca-certificates \
  curl \
  wget \
  net-tools \
  htop \
  nmap \
  gnupg \
  openssh-server \
  fail2ban \
  openssl

echo "===================== SSH servisi ayarlanıyor =========================="
sudo systemctl enable --now sshd

sudo sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

echo "===================== Fail2Ban başlatılıyor =========================="
sudo systemctl enable --now fail2ban

echo "===================== Docker CE repo ekleniyor =========================="
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "===================== Docker kuruluyor =========================="
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker

echo "===================== Docker Compose kuruluyor =========================="
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "===================== Hostname ayarlanıyor =========================="
sudo hostnamectl set-hostname test1

# --------------------------------------------------
# ANSIBLE
# --------------------------------------------------
echo "===================== Ansible kurulumu =========================="

sudo dnf install -y epel-release
sudo dnf makecache
sudo dnf install -y ansible-core

echo "Ansible version:"
ansible --version

# --------------------------------------------------
# K3S
# --------------------------------------------------
echo "===================== K3s kurulumu =========================="

if ! command -v k3s &> /dev/null; then
  curl -sfL https://get.k3s.io | sh -
else
  echo "K3s zaten kurulu, atlanıyor..."
fi

echo "K3s node durumu kontrol ediliyor..."
sleep 30
sudo k3s kubectl get node

# kubectl alias (konfor için)
echo "alias kubectl='sudo k3s kubectl'" | sudo tee /etc/profile.d/kubectl.sh
source /etc/profile.d/kubectl.sh

# --------------------------------------------------
# HELM
# --------------------------------------------------
echo "===================== Helm kurulumu =========================="

if ! command -v helm &> /dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  echo "Helm zaten kurulu, atlanıyor..."
fi

echo "Helm version:"
helm version

# --------------------------------------------------
# DEMO CONTAINER
# --------------------------------------------------
echo "===================== Demo container çalıştırılıyor =========================="
sudo docker rm -f vms-test 2>/dev/null || true
sudo docker pull savaseeratesli/vms-test:latest
sudo docker run -d -p 7000:80 --restart unless-stopped --name vms-test savaseeratesli/vms-test:latest

echo "===================== TÜM KURULUMLAR TAMAMLANDI =========================="
