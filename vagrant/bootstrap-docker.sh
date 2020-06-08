#!/bin/bash
# Remove older versions of Docker
echo "Removing older versions of Docker"
sudo apt-get remove docker docker-engine docker.io

# Kernel version must be over 3.2
echo "[INFO] Keep in mind that kernel version must be at least 3.2"
echo "[INFO] Current version is " $(uname -r)

# Update and install

echo "\nUpdate and install pre-requisites"
sudo apt-get update
sudo apt-get install \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg2 \
      software-properties-common -y

# Docker's official GPG key
echo "\nAdding Docker's official GPG key"
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg -o docker-ce.gpgkey
sudo apt-key add docker-ce.gpgkey

# Add stable branch repository
echo "\nAdd Docker-CE repository"
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# Update repository info and install Docker-CE
echo "\nUpdate repository info and installing Docker-CE"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo groupadd docker
sudo usermod -aG docker vagrant

# Configure docker to start on boot
sudo systemctl enable docker


DOCKER_COMPOSE_VERSION=1.24.1
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose