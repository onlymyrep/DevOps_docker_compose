#!/bin/bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu focal stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo docker swarm init --advertise-addr 192.168.56.10
sudo docker swarm join-token worker | grep 'docker swarm join' > /vagrant/swarm_token.txt
sudo docker network create --driver overlay --attachable overlay
sudo docker stack deploy -c /vagrant/docker-compose.yml shermanb
sudo docker stack deploy -c /vagrant/portainer-stack.yml portainer