#!/bin/bash

echo "===================== Sistem güncelleniyor =========================="
sudo dnf -y update

echo "===================== Firewalld kapatılıyor =========================="
sudo systemctl disable --now firewalld

echo "===================== Gerekli paketler kuruluyor =========================="
sudo dnf install -y \
  ca-certificates \
  curl \
  gnupg \
  wget \
  net-tools \
  htop \
  nmap \
  openssh-server \
  fail2ban

echo "===================== Docker CE repo ekleniyor =========================="
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

echo "===================== Docker kuruluyor =========================="
sudo dnf install -y docker-ce docker-ce-cli containerd.io

echo "===================== Docker servisi başlatılıyor =========================="
sudo systemctl enable --now docker

echo "===================== Docker Compose kuruluyor =========================="
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "===================== Hostname değiştiriliyor =========================="
sudo hostnamectl set-hostname manage

echo "===================== SSH ayarları yapılıyor =========================="
sudo sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl enable --now sshd
sudo systemctl restart sshd

echo "===================== Fail2Ban başlatılıyor =========================="
sudo systemctl enable --now fail2ban

echo "===================== Docker imajı çalıştırılıyor =========================="
sudo docker run -d -p 7000:80 --name vms-test savaseeratesli/vms-test:latest

echo "===================== Kurulum tamamlandı =========================="
