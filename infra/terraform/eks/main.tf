terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    # Configure in terraform.tfvars or CLI
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# Get the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# NETWORKING (VPC)
# ---------------------------------------------------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = [] # No private subnets to save NAT Gateway costs
  public_subnets  = var.public_subnets

  enable_nat_gateway = false
  single_nat_gateway = false
  
  map_public_ip_on_launch = true

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "k3s_node" {
  name        = "${var.project_name}-k3s-sg"
  description = "Security group for K3s node"
  vpc_id      = module.vpc.vpc_id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Warning: Restrict this in production
  }

  # HTTP/HTTPS Access (Traefik Ingress)
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

  # K8s API Access (Optional, for remote kubectl)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Warning: Restrict this in production
  }
  
  # NodePort Range (for testing services directly if needed)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# COMPUTE (EC2 K3s Node)
# ---------------------------------------------------------------------------------------------------------------------
# User Data script to install K3s
locals {
  user_data = <<-EOT
    #!/bin/bash
    # Update system
    apt-get update && apt-get upgrade -y
    
    # Install K3s (Lightweight Kubernetes)
    # We disable Traefik here if we want to install it manually, but for simplicity we keep it.
    # We allow writing kubeconfig with mode 644 for easy download (Warning: Security risk, dev only)
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  EOT
}

resource "aws_instance" "k3s_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type # t3.micro (free tier)

  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.k3s_node.id]
  associate_public_ip_address = true
  
  # IAM Role (for potential SSM access or S3 access)
  iam_instance_profile = aws_iam_instance_profile.k3s_node_profile.name

  user_data = base64encode(local.user_data)
  
  # Root block device - 20GB is free tier eligible (up to 30GB total)
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project_name}-k3s-node"
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "k3s_node_role" {
  name = "${var.project_name}-k3s-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.k3s_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "k3s_node_profile" {
  name = "${var.project_name}-k3s-profile"
  role = aws_iam_role.k3s_node_role.name
}

# ---------------------------------------------------------------------------------------------------------------------
# ECR REPOSITORY (Optional, if using ECR instead of Docker Hub)
# The user asked for Docker Hub, but keeping ECR terraform for completeness/backup is good practice, 
# though we won't use it in the pipeline if using Docker Hub. 
# We'll leave it out to save complexity/potential cost if not cleaned up.
# ---------------------------------------------------------------------------------------------------------------------