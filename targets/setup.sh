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
  
apt install -y \
  redis-server \
  apache2 \
  squid

# add some entries to /etc/hosts
if [[ ! -e etc.hosts ]]; then
  echo "10.5.0.10 test.example.com" | cat >> /etc/hosts
  echo "10.5.0.10 restricted.example.com" | cat >> /etc/hosts

  touch etc.hosts
fi

# alqasr
wget https://github.com/alqasr/alqasr/releases/download/v0.1.0/alqasr_0.1.0_linux_arm64.zip
unzip -o alqasr_0.1.0_linux_arm64.zip -d /usr/local/bin

chown proxy:proxy /usr/local/bin/alqasr_auth
chown proxy:proxy /usr/local/bin/alqasr_acl

# squid conf
mv /etc/squid/squid.conf /etc/squid/squid.old
cp /vagrant/etc/squid/squid.conf /etc/squid/squid.conf
systemctl restart squid
