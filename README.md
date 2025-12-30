# Professional FastAPI CI/CD & GitOps Showcase

This project demonstrates a production-grade **End-to-End DevOps Pipeline** for a FastAPI application. It integrates Infrastructure as Code (IaC), Continuous Integration (CI), Continuous Deployment (CD), and GitOps principles to provide a robust, automated deployment lifecycle on AWS.

## 🚀 Architecture Overview

![DevOps Architecture Diagram](docs/assets/architecture.png)

The system is built on a highly automated architecture that ensures stability, security, and scalability.

<details>
<summary>View Mermaid Logic Diagram</summary>

```mermaid
graph TD
    A[Local Development] -->|Push to Git| B[GitHub Repository]
    B -->|Trigger| C[CI Pipeline: GHA]
    C -->|Build & Push| D[Docker Hub]
    C -->|Security Scan| E[Trivy & Bandit]
    B -->|Trigger| F[CD Pipeline: GHA]
    F -->|Terraform Apply| G[AWS Infrastructure]
    G -->|Launch| H[EC2: m7i-flex.large]
    H -->|Clusters| I[K3s Cluster]
    I -->|GitOps Sync| J[ArgoCD]
    J -->|Deploys| K[FastAPI App]
    K -->|Monitored by| L[Prometheus & Grafana]
```
</details>

## 🛠️ Key DevOps Skills & Technologies

### 1. Infrastructure as Code (IaC) - Terraform
- Multi-environment setup using **Terraform**.
- **S3 Remote Backend** for secure state management and team collaboration.
- Automated provisioning of **VPC**, **Security Groups**, **IAM Roles**, and **m7i-flex.large** EC2 instances.

### 2. Containerization - Docker
- **Dockerized** FastAPI application using multi-stage builds for minimal image size.
- Automated image tag management within the CI/CD pipeline.

### 3. CI/CD Pipeline - GitHub Actions
- **Continuous Integration**: Automated linting (**Flake8**), security scanning (**Bandit**, **Trivy**), and Docker image building.
- **Continuous Deployment**: Automated Terraform plan/apply and GitOps manifest updates.
- Robust secret management using GitHub Secrets.

### 4. GitOps - ArgoCD
- Industry-standard **GitOps** flow using **ArgoCD**.
- Automatic synchronization of Kubernetes manifests from the repository to the live cluster.
- Self-healing capabilities to ensure the desired state is always maintained.

### 5. Kubernetes - K3s
- Lightweight **K3s** cluster deployment on AWS.
- Configured **Inbound/Outbound** rules for secure access.
- Managed **Resources Requests/Limits** to prevent container starvation.

### 6. Observability & Security
- **Monitoring**: Integrated **Prometheus** for metrics collection and **Grafana** for visualization.
- **Security**: Automated vulnerability scanning and least-privilege IAM policies.
- **Logging**: Advanced EC2 launch logging for easier troubleshooting.

## 💻 Setup & Usage

### Prerequisites
- AWS Account & Credentials.
- GitHub Account with repository specific secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `DOCKER_USERNAME`, `DOCKERHUB_TOKEN`, `TF_STATE_BUCKET`).

### Local Development
1. Clone the repository.
2. Install dependencies: `pip install -r requirements.txt`.
3. Run locally: `uvicorn app.src.main:app --reload`.

### Triggering Deployment
Simply push your changes to the `main` branch. The GitHub Actions pipeline will:
1. Build and push the Docker image.
2. Update the infrastructure via Terraform.
3. Update the Kubernetes manifests, triggering an ArgoCD sync.

## 🔍 How to Access & Observe

### 1. Web Access
Once the deployment finishes, use your **Public IP**:
- **FastAPI App**: `http://<PUBLIC_IP>/`
- **Swagger Docs**: `http://<PUBLIC_IP>/docs`
- **Prometheus**: `http://<PUBLIC_IP>/prometheus`
- **Grafana**: `http://<PUBLIC_IP>/grafana` (admin/admin)

### 2. Remote CLI Access (kubectl)
I've provided a **Zero-SSH** script to link your local machine to the AWS cluster:
1. Run: `chmod +x setup-kube.sh`
2. Run: `./setup-kube.sh <PUBLIC_IP> <TF_STATE_BUCKET_NAME>`

This method uses the **AWS CLI** to securely fetch the configuration from S3, eliminating the need for SSH keys or manual configuration.

## 📈 Portfolio Highlights
This project serves as a comprehensive demonstration of:
- **Automation First** mindset.
- **Infrastructure as Code** mastery.
- **Secure DevOps** practices.
- **Cloud-Native** architecture design.

---
*Created by [Thomas Asamba](https://github.com/thomasasamba-bot) as a professional DevOps showcase.*
