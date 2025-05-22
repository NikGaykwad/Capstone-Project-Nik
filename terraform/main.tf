# Define local variables
locals {
  vpc_id           = "vpc-06111e9cc534c08dd"
  subnet_id        = "subnet-04d562ce923deb26a"
  ssh_user         = "ubuntu"
  key_name         = "lab1"
  private_key_path = "/var/lib/jenkins/.ssh/lab1.pem"
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
    from_port   = 8080
    to_port     = 8080
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

# EC2 instance
resource "aws_instance" "web" {
  ami                         = "ami-03bb6d83c60fc5f7c"  # Ubuntu 22.04 (ap-south-1)
  instance_type               = "t2.micro"
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = local.key_name
  associate_public_ip_address = true

  tags = {
    Name = "boardgame-web"
  }
}

# Output EC2 Public IP
output "instance_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of the EC2 instance"
}

