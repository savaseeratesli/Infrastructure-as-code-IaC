#!/bin/bash

sudo su
sudo -i

echo "===================== Değişken tanımları yapılıyor =========================="

export MASTER_IP="192.168.68.50"
export WORKER_IP="192.168.68.51"
export NODE_NAME="k3s-master1"
export HOSTNAME_MASTER="master1"
export HOSTNAME_WORKER="worker1"

echo ${MASTER_IP}

echo ${WORKER_IP}

echo ${NODE_NAME}  

echo ${HOSTNAME_MASTER}

echo ${HOSTNAME_WORKER}


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
sudo hostnamectl set-hostname ${HOSTNAME_MASTER}

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
  htop \
  nmap \
  fail2ban \
  git
  
echo "===================== K3S kurulumu =========================="

sudo -i 

curl -sfL https://get.k3s.io | sh -s - server --node-ip=${MASTER_IP} --bind-address=${MASTER_IP} --advertise-address=${MASTER_IP}

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

echo "===================== Master Token =========================="

export TOKEN=$(tr -d '\n' < /var/lib/rancher/k3s/server/token)
echo ${TOKEN}

echo "===================== Master Node Kurulumu Tamamlandı =========================="
