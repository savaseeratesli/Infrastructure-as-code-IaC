#!/bin/bash

set -e

MASTER_IP="192.168.68.50"
WORKER_IP="192.168.68.51"
HOSTNAME_MASTER="master1"
HOSTNAME_WORKER="worker1"
K3S_TOKEN="K10d2f68f8a149ee1fb207fb89cadda64b243dbeb6146b8fc4205a20022e1774d3b::server:b769cbcd847e2341432b5cc3a9473d1c"

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
sudo hostnamectl set-hostname ${HOSTNAME_WORKER}

echo "===================== Kurulum dizini ayarlanıyor =========================="
sudo -i export PATH=$PATH:/usr/local/bin

echo "===================== Swap kapatılıyor =========================="
sudo swapoff -a
sudo -i sed -i '/swap/d' /etc/fstab

echo "===================== Hosts ekleniyor =========================="

echo "${MASTER_IP} ${HOSTNAME_MASTER}" | sudo tee -a /etc/hosts
echo "${WORKER_IP} ${HOSTNAME_WORKER}" | sudo tee -a /etc/hosts

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

sudo sysctl --system


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
  net-tools \
  nmap     
  
echo "===================== K3S kurulumu =========================="

sudo -i 

curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${K3S_TOKEN} sh -s - agent --node-ip=${WORKER_IP} --node-label node-role.kubernetes.io/worker=

echo "K3s node durumu kontrol ediliyor..."
sleep 30


echo "===================== Helm kurulumu =========================="

sudo -i 

curl -fsSL https://get.helm.sh/helm-v4.0.4-linux-amd64.tar.gz | sudo tar -xz
sudo mv linux-amd64/helm /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm

# Root PATH fix 
if ! grep -q "/usr/local/bin" /root/.bashrc; then
  echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc
fi

echo "===================== Worker Node Kurulumu Tamamlandı =========================="

