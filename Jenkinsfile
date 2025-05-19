pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        SONAR_PROJECT_KEY = 'sonar'
        SONAR_HOST_URL = 'http://43.205.183.138:9000/'
        DOCKER_IMAGE = "nikhilg032/boardgame-webapp"
        DOCKER_CREDENTIALS_ID = 'Docker-Access-Token'

        // Dynamically fetch EC2 Public IP from Terraform
        EC2_PUBLIC_IP = sh(script: "terraform output -raw instance_public_ip", returnStdout: true).trim()
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/NikGaykwad/Capstone-Project-Nik.git'
            }
        }

        stage('Initialize Terraform') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    script {
                        dir('/home/ubuntu/board-game-project/terraform/') {
                            sh '''
                                export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                terraform init
                            '''
                        }
                    }
                }
            }
        }

        stage('Terraform Apply - Provision EC2 Instance') {
            steps {
                withCredentials([aws(credentialsId: 'aws-credentials')]) {
                    script {
                        dir('/home/ubuntu/board-game-project/terraform/') {
                            sh '''
                                export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                terraform apply -auto-approve
                            '''
                        }
                    }
                }
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                script {
                    dir('/home/ubuntu/board-game-project/terraform/') {
                        def output = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                        env.INSTANCE_IP = output
                        echo "New EC2 Instance IP: ${env.INSTANCE_IP}"
                    }
                }
            }
        }

        stage('Wait for EC2 to be Ready') {
            steps {
                script {
                    sleep(30)  // Wait for setup completion
                }
            }
        }

        stage('Build & Test') {
            steps {
                sh 'mvn clean package -T 1C -DskipTests=false'
            }
        }

        stage('SonarQube Scan') {
            steps {
                withCredentials([string(credentialsId: 'sonar', variable: 'SONAR_LOGIN')]) {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            mvn sonar:sonar \
                                -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                                -Dsonar.host.url=$SONAR_HOST_URL \
                                -Dsonar.login=$SONAR_LOGIN
                        '''
                    }
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    docker build -t boardgame-temp .
                    trivy image --exit-code 0 --severity HIGH,CRITICAL boardgame-temp
                '''
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                sh '''
                    mkdir -p owasp-report
                    dependency-check.sh --project "BoardGame" --scan ./ --out ./owasp-report
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:$BUILD_NUMBER .'
            }
        }

        stage('Docker Login & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "Docker-Access-Token",
                    passwordVariable: 'DOCKER_PASS',
                    usernameVariable: 'DOCKER_USER'
                )]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push $DOCKER_IMAGE:$BUILD_NUMBER
                    '''
                }
            }
        }

        stage('Deploy to EC2 using Ansible') {
            steps {
                dir('ansible') {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'ec2-ssh-key',
                        keyFileVariable: 'SSH_KEY'
                    )]) {
                        sh '''
                            ansible-playbook -i inventory ansible-deploy.yml --private-key $SSH_KEY
                        '''
                    }
                }
            }
        }

        stage('Post-deploy Health Check') {
            steps {
                sh '''
                    for i in {1..5}; do 
                        curl -f http://$EC2_PUBLIC_IP:8080/actuator/health && break || sleep 5
                    done
                '''
            }
        }
    }

    post {
        failure {
            echo '❌ Pipeline failed! Check logs.'
        }
        success {
            echo '✅ Deployment successful 🚀'
        }
    }
}

