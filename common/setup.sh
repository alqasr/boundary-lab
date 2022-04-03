#!/usr/bin/env bash

apt-get update
apt-get upgrade -y

# install packages
apt-get install -y \
  ca-certificates \
  curl \
  git \
  gnupg \
  lsb-release \
  net-tools \
  unzip

# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

docker --version

if [[ ! -e /usr/local/bin/docker-compose ]]; then
  curl -L "https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi
