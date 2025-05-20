# Define local variables
locals {
  vpc_id           = "vpc-06111e9cc534c08dd"
  subnet_id        = "subnet-04d562ce923deb26a"
  ssh_user         = "ubuntu"
  key_name         = "lab1"
  private_key_path = "/var/lib/jenkins/.ssh/lab1.pem"  # Path of the key
}

# AWS provider block
provider "aws" {
  region = "ap-south-1"
}

# Security Group for EC2
resource "aws_security_group" "web_sg" {
  name   = "terraform-iac"  
  vpc_id = local.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance resource
resource "aws_instance" "web_server" {
  ami                         = "ami-0e35ddab05955cf57"
  instance_type               = "t2.small"
  subnet_id                   = local.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id] 
  key_name                    = local.key_name

  tags = {
    Name = "Boardgame-WebApp-Server"
  }

  # Remote exec provisioner to install Java
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install openjdk-17-jdk -y",
      "sudo mkdir -p /opt/boardgame-app"
    ]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = self.public_ip
    }
  }

  # Just a success message
  provisioner "local-exec" {
    command = "echo 'Java installed successfully!'"
  }
}

