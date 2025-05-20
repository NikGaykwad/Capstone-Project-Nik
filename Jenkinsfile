pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-south-1'
        SONAR_PROJECT_KEY = 'sonar'
        SONAR_HOST_URL = 'http://3.111.185.253:9000/'
        DOCKER_IMAGE = "nikhilg032/boardgame-webapp"
        DOCKER_CREDENTIALS_ID = 'Docker-Access-Token'
        APP_DIR = 'app/BoardGame'
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials', url: 'https://github.com/NikGaykwad/Capstone-Project-Nik.git'
            }
        }

        stage('Initialize Terraform') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_credentials']]) {
                    dir('terraform') {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            terraform init
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply - Provision EC2 Instance') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_credentials']]) {
                    dir('terraform') {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Get EC2 Public IP') {
            steps {
                script {
                    dir('terraform') {
                        def output = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                        env.INSTANCE_IP = output
                        echo "✅ EC2 Instance IP: ${env.INSTANCE_IP}"
                    }
                }
            }
        }

        stage('Wait for EC2 to be Ready') {
            steps {
                script {
                    sleep(30)
                }
            }
        }

        stage('Build & Test') {
            steps {
                dir("${env.APP_DIR}") {
                    sh 'mvn clean package -T 1C -DskipTests=false'
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                withCredentials([string(credentialsId: 'Sonar', variable: 'SONAR_LOGIN')]) {
                    withSonarQubeEnv('SonarQube') {
                        dir("${env.APP_DIR}") {
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
        }

        stage('Trivy Scan') {
            steps {
                dir("${env.APP_DIR}") {
                    sh '''
                        docker build -t boardgame-temp .
                        trivy image --exit-code 0 --severity HIGH,CRITICAL boardgame-temp
                    '''
                }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dir("${env.APP_DIR}") {
                    sh '''
                        mkdir -p owasp-report
                        dependency-check.sh --project "BoardGame" --scan ./ --out ./owasp-report
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir("${env.APP_DIR}") {
                    sh 'docker build -t $DOCKER_IMAGE:$BUILD_NUMBER .'
                }
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

        stage('Update Ansible Inventory & Deploy') {
            steps {
                dir('ansible') {
                    script {
                        // Inject EC2 IP dynamically into inventory.ini
                        sh """
                            echo '[web]' > inventory.ini
                            echo '${env.INSTANCE_IP} ansible_user=ubuntu' >> inventory.ini
                        """
                    }
                    withCredentials([sshUserPrivateKey(
                        credentialsId: 'SSH-Key',
                        keyFileVariable: 'SSH_KEY'
                    )]) {
                        sh '''
                            ansible-playbook -i inventory.ini ansible-deploy.yml --private-key $SSH_KEY
                        '''
                    }
                }
            }
        }

        stage('Post-deploy Health Check') {
            steps {
                script {
                    sh '''
                        for i in {1..5}; do
                            curl -f http://$INSTANCE_IP:8080/actuator/health && break || sleep 5
                        done
                    '''
                }
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

