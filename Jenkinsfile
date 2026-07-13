pipeline {
    agent any

    environment {
        ARM_CLIENT_ID       = credentials('azure-client-id')
        ARM_CLIENT_SECRET   = credentials('azure-client-secret')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        ARM_TENANT_ID       = credentials('azure-tenant-id')
        DOCKERHUB_CREDS     = credentials('dockerhub-creds')
        IMAGE_NAME          = "hafdevops/helloworld-app"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform init -input=false -migrate-state'
                    sh 'terraform apply -auto-approve -input=false'
                }
            }
        }

        stage('Capture VM IP') {
            steps {
                dir('terraform') {
                    script {
                        env.VM_IP = sh(
                            script: "terraform output -raw public_ip",
                            returnStdout: true
                        ).trim()
                    }
                }
                echo "VM public IP: ${env.VM_IP}"
            }
        }

        stage('Wait for VM to be SSH-ready') {
            steps {
                sh """
                    for i in \$(seq 1 30); do
                        nc -z -w2 ${env.VM_IP} 22 && echo "SSH is up" && exit 0
                        echo "Waiting for SSH on ${env.VM_IP}..."
                        sleep 10
                    done
                    echo "Timed out waiting for SSH"
                    exit 1
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} -t ${IMAGE_NAME}:latest ./app"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh "echo \$DOCKERHUB_CREDS_PSW | docker login -u \$DOCKERHUB_CREDS_USR --password-stdin"
                sh "docker push ${IMAGE_NAME}:${BUILD_NUMBER}"
                sh "docker push ${IMAGE_NAME}:latest"
            }
        }

        stage('Deploy to Azure VM over SSH') {
            steps {
                sshagent(credentials: ['azure-vm-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no azureuser@${env.VM_IP} '
                            docker pull ${IMAGE_NAME}:latest &&
                            docker stop helloworld-app || true &&
                            docker rm helloworld-app || true &&
                            docker run -d --name helloworld-app -p 5000:5000 ${IMAGE_NAME}:latest
                        '
                    """
                }
            }
        }
    }

    post {
        always {
            sh "docker logout || true"
        }
        success {
            echo "App deployed. Try: curl http://${env.VM_IP}:5000"
        }
    }
}
