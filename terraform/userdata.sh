#!/bin/bash
echo "INFO: Installing required packages"
sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg lsb-release -y

sudo mkdir -p /etc/apt/keyrings
if [ -f "/etc/apt/keyrings/docker.gpg" ]; then
	echo ""
else
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing the Docker Engine"
sudo apt-get update -y

if [[ $? -ne 0 ]]; then
	echo "Incase of any GPG error"
	sudo chmod a+r /etc/apt/keyrings/docker.gpg
	sudo apt-get update
fi

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

echo "INFO: Starting the docker service"
sudo systemctl start docker

echo "INFO: Enabling the docker server"
sudo systemctl enable docker

echo "INFO: Granting ubuntu user docker access"
sudo usermod -a -G docker ubuntu
