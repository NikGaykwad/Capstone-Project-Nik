# Capstone-Project-Nik
This is my capstone project

------------------------------------------------------------------------------------------------------------------------------------------------------------------
Script to install DevOps Tools

#!/bin/bash

echo "🚀 Starting Full DevSecOps Environment Setup..."

# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Core tools
sudo apt install -y git curl wget unzip zip vim tree telnet net-tools software-properties-common gnupg lsb-release python3-pip

# 3. Java (needed for Jenkins and Spring Boot apps)
sudo apt update -y
sudo apt install -y fontconfig openjdk-17-jre
java -version  # Verify Java installation

# 4. Maven (for Java project builds)
sudo apt install -y maven

# 5. Docker
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# 6. Ansible
sudo apt update && sudo apt upgrade -y && sudo apt install -y python3 python3-pip openssl ansible

# 7. Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# 8. Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install -y terraform
terraform --version

# 9. Trivy (for container scanning)
curl -sfL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt update && sudo apt install -y trivy

# 10. AWS CLI v2
echo "📦 Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
rm -rf aws awscliv2.zip

# 11. OWASP Dependency-Check CLI (v8.4.0)
echo "🔍 Installing OWASP Dependency-Check..."
cd /opt
sudo wget https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
sudo unzip dependency-check-8.4.0-release.zip -d /opt/
sudo ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
dependency-check --version
cd ~

echo ""
echo "✅ DevSecOps tools installed successfully!"
echo "🔁 Please reboot or logout/login to apply Docker group permissions."
echo "🔐 To configure AWS CLI, run: aws configure"


-------------------------------------------------------------------------------------------------------------------------------------------------------------------

🔧 Infrastructure Automation:
Provisioned scalable EC2 instances on AWS using Terraform and Ansible for repeatable deployments.

⚙️ CI/CD Pipeline:
Implemented end-to-end pipelines using Jenkins and GitHub Actions for seamless build, test, and deployment — ensuring zero-downtime releases.

🔐 Security & Compliance:
Integrated Spring Security, enforced auth mechanisms, and performed vulnerability scanning using SonarQube, Trivy, and OWASP Dependency Check.

📊 Monitoring & Logging:
Set up real-time dashboards using Prometheus and Grafana, and integrated CloudWatch for log tracking and performance tuning.

It was a great hands-on journey building this end-to-end DevOps pipeline! 💻🚀

