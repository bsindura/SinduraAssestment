# Sindhura Test
Thanks for your test, I tried multiple ways to address the issue but due to limitation with free-tier I used virtual machine with docker.

We could also use either ECS with fargate or EKS.

## Pre-requisites
An admin or EC2 and S3 full access privileged user keys are needed

## Setting up local machine
1. Login to AWS and create a ubuntu latest t2.micro machine
2. Run the script [setmeup.sh](setmeup.sh) to setup below
  - AWS: Setup the awscli and creates S3 bucket to store the terraform state file (provide the keys as needed when prompted)

3. Setting up docker as we will be using docker build inside Jenkins
4. Setting up Jenkins and granting jenkins user admin access
  - Java: It installs java 11
  - Jenkins: Latest Jenkins will be installed
  - Verifies the health of the Jenkins

5. Setting up the keys.  We will be using this key to spin up our target infrastructure (EC2)
6. Please import the public into AWS account

## Setting up Jenkins
1. Access the http:<publicip>:8080 and follow the instructions
2. Install docker, docker-pieline, declarative pipeline, sshagent plugins and restart the instance
3. Login to hub.docker.com and generate api key;
4. Create username and password credential for `DOCKERHUB_CRED`
5. Create username and password credentials for `AWS_CRED` (to be used for terraform)
6. Create a username and SSH Private Key for `ubuntu` user (you need to use the private key generated above)

## Creating Job
1. Configure a multi branch or normal pipeline job and point to this repo `main` branch
2. Update the Jenkinsfile with your S3 bucket name
3. Run the job now

## How Jenkins job works
1. Checks out the code
2. Credentials are read and environment is ready for deployment
3. stage `Build & Test` runs inside the docker image to perform build and test
4. stage `Build Docker Image & Publish` is used create the docker image for deployment
5. stage `update infra` will create my target environment which is,
  - VPC
  - IGW
  - Public Subnet
  - Routes
  - Security Group
  - EIP
  - EIP Association
  - VM
:NOTE: I tried to use user_data inside the aws_instance resource it self however it is not getting run as I used few special characters so I commented that part and running a script during infra creation
6. stage `Deploy` is going to prepare  my environemnt, making sure it has all the required softwares like docker, and ubuntu user access to docker group.  And then it pulls the docker image and runs in on port 8080.
:NOTE: I assumed it is going to be a first time run.  We can also enhance it by checking if port 8080 is free, if not then we can stop and prune the container and run it with newer version of docker image


## To test or run manually
1. Import the key into AWS and export variable <br/>
`export key_name=mykeyname`
2. Clone the repo and go to terraform folder <br/>
`cd terraform`
3. Export AWS variables <br/>
```bash
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_REGION="us-east-1"
```
4. Initial the Backend <br/>
`terraform init --backend-config="bucket=mybucket" --backend-config="key=mystatefile"`
5. Run the plan <br/>
`terraform plan -var-file prod.tfvars`
6. Apply the changes <br/>
`terraform apply -var-file prod.tfvars --auto-approve`
7. Get the public ip from the output and login to the server <br/>
`ssh -i <myprivatekey> ubuntu@<pip>`
8. Run the userdata.sh script which will install the docker <br/>
`sh userdata.sh`
9. You may need to relogin as current shell may not get docker privileges
10. Docker commands
```bash
docker login -u <username> -p <password>
docker pull sindhurab/mytest:latest
docker run -d -p 8080:8080 sindhurab/mytest:latest
```
11. Now access the application http://<PIP>:8080
