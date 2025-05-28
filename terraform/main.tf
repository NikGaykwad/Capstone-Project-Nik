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

# 🔹 CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/boardgame-web"
  retention_in_days = 30
}

# 🔹 CloudWatch Log Stream for EC2
resource "aws_cloudwatch_log_stream" "web_log_stream" {
  name           = "boardgame-web-stream"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
}

# 🔹 IAM Policy for CloudWatch Logging
resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "CloudWatchLoggingPolicy"
  description = "Allows EC2 to write logs to CloudWatch"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.app_logs.arn}/*"
      }
    ]
  })
}

# 🔹 IAM Role for EC2 Logging
resource "aws_iam_role" "ec2_logging_role" {
  name = "ec2_logging_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_logging_policy" {
  role       = aws_iam_role.ec2_logging_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}

# 🔹 EC2 instance with CloudWatch Logging
resource "aws_instance" "web" {
  ami                         = "ami-03bb6d83c60fc5f7c"
  instance_type               = "t2.micro"
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = local.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_role.ec2_logging_role.name  # 👈 CloudWatch IAM Role

  # �� Install CloudWatch Agent Automatically
  user_data = <<EOF
#!/bin/bash
sudo apt update -y
sudo apt install -y amazon-cloudwatch-agent

# Create CloudWatch Agent config
cat <<EOT > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "/aws/ec2/boardgame-web",
            "log_stream_name": "boardgame-web-stream"
          }
        ]
      }
    }
  }
}
EOT

# Start CloudWatch Agent
sudo amazon-cloudwatch-agent-ctl -a start
EOF

  tags = {
    Name = "boardgame-web"
  }
}

# 🔹 Output EC2 Public IP
output "instance_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP of the EC2 instance"
}

