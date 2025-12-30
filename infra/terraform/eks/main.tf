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

# Use the Default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnets from the Default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

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
# SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "k3s_node" {
  name        = "${var.project_name}-k3s-sg"
  description = "Security group for K3s node"
  vpc_id      = data.aws_vpc.default.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP/HTTPS Access (Traefik Ingress)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ArgoCD UI (Initial port)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # K8s API Access
  ingress {
    from_port   = 6443
    to_port     = 6443
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
locals {
  user_data = <<-EOT
    #!/bin/bash
    # Update system
    apt-get update && apt-get upgrade -y
    apt-get install -y curl jq
    
    # Install K3s
    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    # Wait for nodes to be ready
    while ! kubectl get nodes | grep -q "Ready"; do sleep 5; done

    # Install ArgoCD
    kubectl create namespace argocd || true
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    # Wait for ArgoCD server to be ready
    while ! kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server | grep -q "Running"; do sleep 10; done

    # Apply the Application manifest
    cat <<EOF | kubectl apply -f -
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: fastapi-app
      namespace: argocd
    spec:
      project: default
      source:
        repoURL: "https://github.com/thomasasamba-bot/fastapi-ci-cd-project.git"
        targetRevision: HEAD
        path: infra/kubernetes/app
      destination:
        server: "https://kubernetes.default.svc"
        namespace: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
    EOF
  EOT
}

resource "aws_instance" "k3s_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.k3s_node.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.k3s_node_profile.name

  user_data = base64encode(local.user_data)
  
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