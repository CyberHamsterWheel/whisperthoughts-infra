sudo apt-get update -y
sudo apt-get install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker

# Install K3s - a lightweight K8s distribution
curl -sfL https://get.k3s.io | sh -
echo "K3s installed!"