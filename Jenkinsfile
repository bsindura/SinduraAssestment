pipeline {
    agent any
    environment {
        DOCKER_CREDS = credentials('DOCKERHUB_CRED')
        TERRAFORM_CRED = credentials('AWS_CRED')
        S3_BUCKET_NAME = "sindhuratest"
        AWS_REGION = 'us-east-1'
        AWS_ACCESS_KEY_ID = "$TERRAFORM_CRED_USR"
        AWS_SECRET_ACCESS_KEY= "$TERRAFORM_CRED_PSW"
    }
    parameters {
        choice choices: ['prod', 'dev'], description: 'Target Environment to create and deploy resource', name: 'TARGET_ENV'
    }
    stages {
        stage('Build & Test') {
            agent {
                docker {
                    image 'node:16-alpine3.16'
                    args '-u root:root'
                    reuseNode true
                }
            }
            steps {
                sh """
                    cd src
                    npm install
                    npm run test
                """
            }
            post {
                success {
                    echo "Build completed successfully"
                }
                failure {
                    echo "Failed to compile and build the code, please verify the logs for more information"
                }
            }
        }
        stage('Build Docker Image & Publish') {
            steps {
                sh """
                    docker build -t sindhurab/mytest:myapp-${BUILD_NUMBER} .
                    docker login -u $DOCKER_CREDS_USR -p $DOCKER_CREDS_PSW
                    docker push sindhurab/mytest:myapp-${BUILD_NUMBER}
                """
            }
        }
        stage('Update Infra') {
            agent {
                docker {
                    image 'hashicorp/terraform'
                    reuseNode true
                }
            }
            steps {
                sh """
                    cd terraform
                    #export AWS_ACCESS_KEY_ID=${TERRAFORM_CRED_USR}
                    #export AWS_SECRET_ACCESS_KEY=${TERRAFORM_CRED_PSW}
                    #export AWS_REGION=${AWS_REGION}
                    terraform init \
                      --backend-config="bucket=${S3_BUCKET_NAME}" \
                      --backend-config="key=${TARGET_ENV}.tfstate"
                    terraform plan -var-file ${TARGET_ENV}.tfvars
                    terraform apply -var-file ${TARGET_ENV}.tfvars
                """
            }
        }
        stage('Deploy') {
            steps {
                sh """
                    TARGET_SERVER=`terraform output public_ip | sed 's/"//g'`
                    sshagent(['ubuntu']) {
                        scp -o StrictHostKeyChecking=no userdata.sh ubuntu@${TARGET_SERVER}:/tmp/userdata.sh
                        ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_SERVER} sh /tmp/userdata.sh
                    }
                """

                sh """
                    TARGET_SERVER=`terraform output public_ip | sed 's/"//g'`
                    sshagent(['ubuntu']) {
                       
                        ssh -o StrictHostKeyChecking=no ubuntu@${TARGET_SERVER} \
                        \"docker login -u $DOCKER_CREDS_USR -p $DOCKER_CREDS_PSW; \
                          docker pull sindhurab/mytest:myapp-${BUILD_NUMBER}; \
                          docker run -d -p 8080:8080 sindhurab/mytest:myapp-${BUILD_NUMBER} \"
                    }
                """
            }
        }
    }
}
