# AWS ECS Fargate: Enterprise CI/CD & Observability Pipeline

`![Architecture](./assets/ECSarchitectural-diagram.png)`

## 📌 Project Overview
This repository contains a production-grade, automated infrastructure stack for deploying containerized applications to AWS. Utilizing **Terraform** for Infrastructure as Code (IaC) and **GitHub Actions** for CI/CD, the pipeline ensures a "Zero-Touch" deployment process from code push to a live environment.

The architecture focuses on high availability, security hardening, and cost-optimization using serverless compute.

## 🚀 Tech Stack
* **Cloud Provider:** AWS (VPC, ECS, ECR, ALB, Route 53, ACM, CloudWatch)
* **IaC:** Terraform (Modularized)
* **Backend & State:** HCP Terraform (Terraform Cloud)
* **CI/CD:** GitHub Actions
* **Containerization:** Docker
* **Notifications:** Slack via Webhooks

## 🏗️ Key Architectural Features
- **Security-First Networking:** Application compute is restricted to **Private Subnets**, accessible only via an Application Load Balancer in the Public Subnets.
- **Atomic Versioning:** Uses the **GitHub Commit SHA** as the unique image tag in ECR and Task Definitions, enabling perfect audit trails and easy rollbacks.
- **Automated SSL/TLS:** Integrated Route 53 and ACM for automated certificate validation and HTTPS enforcement.
- **Immutable Infrastructure:** Every deployment creates a new ECS Task Revision, ensuring no "configuration drift" occurs on the live servers.

## 🛠️ Infrastructure Modules
The project is split into reusable Terraform modules:
* `/modules/network`: VPC, Subnets, IGW, and NAT Gateways.
* `/modules/iam`: Specialized ECS Task Execution and Task Roles.
* `/modules/alb`: Load Balancer, Listeners, and Target Groups.
* `/modules/ecr`: Repository, and Lifecycle policy.
* `/modules/ecs`: Cluster, Service, and Task Definition logic.
* `/modules/dns`: Route 53 Records.
* `/modules/ssl`: SSL Validation.
* `/modules/monitoring`: SNS Topic, CloudWatch Metric Alarm, SNS Topic Subscription, and CloudWatch Dashboard.

## 🚦 Prerequisites
Before deploying, ensure you have:
1. An **AWS Account** with IAM credentials.
2. An **HCP Terraform** account and workspace.
3. **GitHub Secrets** configured:
   - `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
   - `TF_API_TOKEN`
   - `SLACK_WEBHOOK_URL`

## ⚙️ How to Deploy
1. **Clone the Repo:**
   ```bash
   git clone [https://github.com/your-username/your-repo-name.git]

2. Update Variables:
Modify terraform.tfvars or your HCP Terraform workspace variables to match your domain and environment settings.

3. Push to Main:

Bash
git add .
git commit -m "feat: initial deployment"
git push origin main

4. Monitor Slack:
The pipeline will notify your Slack channel once the application is live and provide the ALB DNS URL.

🧹 Cleanup
To tear down the infrastructure and avoid costs:

Go to GitHub Actions -> Infrastructure Cleanup.

Run the workflow manually by cliicking Run workflow.

🧠 Lessons Learned
This project served as a deep dive into modern DevOps practices. Here are the key takeaways from the implementation:

1. Modularization Equals Scalability
Moving from a monolithic main.tf to a Modular Infrastructure (Network, IAM, ECS, ALB etc.) allowed me to isolate changes. If I need to update the load balancer logic, I no longer risk accidentally touching the VPC core networking.

2. The "Latest" Tag is a Risk
Early in the project, I relied on the :latest docker tag. I quickly learned that this creates a "blind spot" in deployments. By switching to a GitHub SHA-based tagging strategy, I achieved 1:1 mapping between code commits and running containers, making rollbacks and debugging significantly faster.

4. Remote State is Non-Negotiable
Transitioning from local state files to HCP Terraform (Terraform Cloud) was a turning point. It taught me the importance of state locking and centralized management in a collaborative environment, preventing "state corruption" that often happens during concurrent runs.