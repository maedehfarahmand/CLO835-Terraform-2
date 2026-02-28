provider "aws" {
  region = "us-east-1"
}

# ECR repo for webapp
resource "aws_ecr_repository" "webapp" {
  name                 = "clo835-webapp"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# ECR repo for mysql
resource "aws_ecr_repository" "mysql" {
  name                 = "clo835-mysql"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in default VPC
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Pick subnet in us-east-1a
data "aws_subnet" "subnet_a" {
  filter {
    name   = "availability-zone"
    values = ["us-east-1a"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group
resource "aws_security_group" "ec2_sg" {
  name   = "clo835-ec2-sg"
  vpc_id = data.aws_vpc.default.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # App ports for Assignment 1
  ingress {
    from_port   = 8080
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort range for Assignment 2
  ingress {
    from_port   = 30000
    to_port     = 32767
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

# EC2 instance using existing LabInstanceProfile
resource "aws_instance" "app_server" {
  ami                    = "ami-0c02fb55956c7d316"  # Amazon Linux 2 us-east-1
  instance_type          = "t3.medium"              # t3.medium needed for kind in Assignment 2
  subnet_id              = data.aws_subnet.subnet_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = "LabInstanceProfile"     # Pre-existing in AWS Academy
  key_name               = var.key_name

  tags = {
    Name = "clo835-app-server"
  }
}

# Outputs
output "ec2_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "webapp_ecr_url" {
  value = aws_ecr_repository.webapp.repository_url
}

output "mysql_ecr_url" {
  value = aws_ecr_repository.mysql.repository_url
}