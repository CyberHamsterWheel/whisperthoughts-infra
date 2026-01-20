#!/bin/bash
sudo apt-get update -y
sudo apt-get install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker

curl -sfL https://get.k3s.io | sh -
echo "K3s installed!"
