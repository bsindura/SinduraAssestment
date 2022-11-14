#!/bin/bash

setup_aws() {
    echo "INFO: Downloading aws cli"
    sudo apt-get install unzip -y
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    echo "INFO: Verifying if aws cli is installed successfully"
    aws --version

    if [ "$?" -ne 0 ]; then
        echo "ERROR: Aws cli installed is not installed..Please have it installed manually"
        exit 1
    fi

    echo "INFO: Exporting aws keys"
    aws configure

    echo "INFO: Creating the S3 bucket for terraform"
    read -p "Please enter s3 bucket name(sindhuratest):" bucket_name

    if [ -z $bucket_name ]; then
        bucket_name="sindhuratest"
        echo "In the if"
    fi
    echo "Bucket Name: $bucket_name"
    aws s3api create-bucket --bucket $bucket_name

    if [ $? -eq 0 ]; then
        echo "INFO: Bucket $bucket_name is created successfully"
    else
        echo "ERROR: Failed to create the bucket name, please if it already exists.  Exiting"
        exit 1
    fi
}

setup_docker() {
    echo "INFO: Installing required packages"
    sudo apt-get update -y
    sudo apt-get install ca-certificates curl gnupg lsb-release -y

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

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
}

setup_jenkins() {
    echo "INFO: Installing Java 11"
    sudo apt-get install -y openjdk-11-java

    echo "INFO: Installing Jenkins"
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install jenkins -y

    echo "INFO: Granting Jenkins user docker access and starting the service"
    sudo usermod -a -G docker jenkins
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to grant Jenkins user access to docker..Exiting"
        exit 1
    fi
    echo "INFO: Waiting for few mins for changes to get reflect"
    java -version
    sleep 5
    sudo systemctl start jenkins
    sudo systemctl enable jenkins

    echo "INFO: Verifying if Jenkins is up and running"
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/login)
    if [ $? -eq "200" ]; then
        echo "SUCCESS: Jenkins is installed successfully"
        echo "Please follow http://localhost:8080 and follow the the instructions given on the screen"
    else
        echo "ERROR: Failed to start/install the jenkins please verify the logs for more information"
        exit 1
    fi
}

setup_keys() {
    echo "INFO: Creating keys"
    ssh-keygen -t rsa -N '' -f /tmp/id_rsa
    if [ $? -eq 0 ]; then
        echo -e "INFO: Please find the keys at \nprivate: /tmp/id_rsa \npublic: /tmp/id_rsa.pub"
        echo "INFO: Please use above keys to import into AWS as well Jenkins"
    else
        echo "WARNING: Failed to generate the keys.  Please generate one manually"
    fi
}
# Setting up required setup
setup_aws
setup_docker
setup_jenkins
setup_keys