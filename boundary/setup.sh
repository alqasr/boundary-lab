#!/usr/bin/env bash

# boundary
if [[ ! -e /home/vagrant/.boundary ]]; then
  cd /vagrant/deployment/docker && bash run all
  
  touch /home/vagrant/.boundary
fi

docker logs -f compose-db-init-1
