# 🚀 Zero-Touch DevOps: End-to-End CI/CD + GitOps Platform

[![CI Pipeline](https://github.com/thomasasamba-bot/fastapi-ci-cd-project/actions/workflows/ci.yaml/badge.svg)](https://github.com/thomasasamba-bot/fastapi-ci-cd-project/actions/workflows/ci.yaml)
[![CD Pipeline](https://github.com/thomasasamba-bot/fastapi-ci-cd-project/actions/workflows/cd.yml/badge.svg)](https://github.com/thomasasamba-bot/fastapi-ci-cd-project/actions/workflows/cd.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.5.0-purple?logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/K3s-Lightweight-blue?logo=kubernetes)](https://k3s.io/)
[![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-orange?logo=argo)](https://argoproj.github.io/argo-cd/)

A production-grade, fully automated **DevSecOps Platform** demonstrating the power of **GitOps**, **Infrastructure as Code**, and **Self-Healing Systems**. This project bootstraps a complete Kubernetes environment on AWS from scratch, deploys a secure FastAPI microservice, and manages its entire lifecycle automatically.

---

## 🏗️ Architecture & Workflow

This project implements a "Zero-Touch" philosophy: developers just push code, and the platform handles the rest.

```mermaid
graph LR
    Push[Code Push] --> CI[CI: Test & Scan]
    CI --> Build[Build & Push Image]
    Build --> CD[CD: Terraform Provision]
    CD --> K8s[Bootstrap K3s Cluster]
    K8s --> Argo[ArgoCD Sync]
    Argo --> App[Deploy Microservices]
    App --> Obs[Monitoring:Prometheus/Grafana]
```

### Key Engineering Highlights
- **Ephemeral Infrastructure**: The entire cloud environment (EC2, VPC, IAM) is provisioned on-demand via **Terraform**.
- **True GitOps**: **ArgoCD** ensures the cluster state *always* matches the Git repository. Manual changes are automatically reverted.
- **Security First**: Integrated vulnerability scanning (**Trivy**), linting (**Flake8**), and SAST (**Bandit**) in the pipeline.
- **Cost efficient**: Automatic teardown capabilities to prevent zombie resources.

---

## 🛠️ Technology Stack

| Domain | Technology | Usage |
|:---|:---|:---|
| **Cloud Provider** | AWS (EC2, S3, IAM) | Underlying infrastructure |
| **IaC** | Terraform | automated infrastructure provisioning |
| **Orchestration** | K3s (Kubernetes) | Lightweight, production-ready cluster |
| **GitOps** | ArgoCD | Continuous Deployment & State Synchronization |
| **CI/CD** | GitHub Actions | Pipeline automation (Build, Test, Deploy, Destroy) |
| **Backend** | FastAPI (Python) | High-performance microservice |
| **Observability** | Prometheus & Grafana | Real-time metrics and dashboards |
| **Networking** | Traefik | Ingress controller for routing |

---

## 🚀 Getting Started

### Prerequisites
- AWS Account & Credentials
- GitHub Repository with Secrets configured:
  - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
  - `DOCKER_USERNAME`, `DOCKERHUB_TOKEN`
  - `TF_STATE_BUCKET` (S3 Bucket for Terraform state)

### 1. Local Development
Clone the repository and verify the app locally using the `Makefile`:

```bash
# Install dependencies
make install

# Run tests
make test

# Build Docker image
make build

# Run locally
make local
```

### 2. Deployment (The Magic ✨)
Trigger the CI/CD pipeline by pushing to the `main` branch. 
The system automates the entire lifecycle:
1.  **CI**: Builds & Tests (GitHub Actions).
2.  **CD**: Provisioning (Terraform) & Deployment (ArgoCD).

**How to verify the app is running:**
Wait ~5-10 minutes for the pipeline to finish, then run:
```bash
make status
```
This will output the **Public IP** of your server. Visit `http://<PUBLIC_IP>` to see the app.

### 3. Automated Lifecycle & Cleanup
To ensure cost efficiency, this project creates ephemeral environments:
- **Auto-Destroy**: A timer is set for **10 minutes** after deployment. If no confirmation action is taken, the `destroy` job automatically triggers to tear down EC2/VPC resources.
- **Manual Destroy**: You can run the "Destroy Infrastructure" workflow manually at any time.
- **Full Cleanup**: The destroy logic includes deleting the Terraform State S3 bucket to leave *zero footprint* on AWS.

---

## 📂 Project Structure

```
├── app/                  # FastAPI Application source code
│   ├── src/              # Application logic
│   ├── Dockerfile        # Container definition
│   └── tests/            # Pytest suite
├── infra/
│   ├── terraform/k3s/    # Terraform IaC for AWS & K3s
│   └── kubernetes/       # K8s manifests (Deployment, Ingress)
├── .github/workflows/    # CI/CD Pipelines (CI, CD, Destroy)
└── Makefile              # Developer convenience scripts
```

---

*This project is part of a Cloud Engineering Portfolio demonstrating advanced automation patterns.*
