# AWS ECS Fargate: Enterprise CI/CD & Observability Pipeline

##  Architectural Diagram

%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#0073bb', 'edgeLabelBackground':'#f4f4f4', 'tertiaryColor': '#f4f4f4'}}}%%
graph TD
    %% Define External Nodes
    Internet((🌍 Users on Internet))

    subgraph "1. Source & CI/CD (GitHub)"
        GitRepo[GitHub Repository]
        GHA[GitHub Actions Runner]
    end

    subgraph "2. Infrastructure & State (HCP Terraform)"
        TFCloud[HCP Terraform Workspace]
    end

    %% Define AWS Cloud Boundaries
    subgraph "3. AWS Region: us-east-1"
        Route53[Route 53 Hosted Zone]
        ACM[ACM Certificate]
        ECR[Amazon ECR: sha-tagged]

        subgraph "AWS VPC (High Availability)"
            
            %% Define Public Subnets
            subgraph "Public Subnet (AZ-A & AZ-B)"
                ALB["Application Load Balancer (HTTPS)"]
                IGW[Internet Gateway]
            end

            %% Define Private Subnets
            subgraph "Private App Subnet (AZ-A & AZ-B)"
                ECS[ECS Service: Fargate Tasks]
                NAT[NAT Gateway]
            end
        end
    end

    %% Define Flows & Relationships (The Golden Thread)
    GitRepo -->|"A. Git Push SHA"| GHA
    GHA -->|"B. docker build/push"| ECR
    GHA -->|"C. terraform apply"| TFCloud
    TFCloud -->|"D. Provisions/Updates"| AWS_Resources[AWS Resources]

    %% External User Flow (DNS/SSL)
    Internet -->|"1. DNS Query"| Route53
    Internet -->|"2. HTTPS Request"| ALB
    ACM -.->|"SSL Validation"| ALB

    %% Internal Traffic & Image Flow
    ALB -->|"3. Routes Traffic (Target Group)"| ECS
    ECS -->|"4. Pulls Image via SHA"| ECR

    %% Define Notifications
    GHA -.->|Start/End Status| Slack((Slack))
    TFCloud -.->|Apply Status| Slack((Slack))

    %% Styling (AWS Blue, HashiCorp Purple)
    classDef git fill:#f6f8fa,stroke:#d1d5da,stroke-width:2px,color:#24292e;
    classDef aws fill:#FF9900,stroke:#fff,stroke-width:1px,color:#fff;
    classDef aws_blue fill:#0073bb,stroke:#fff,stroke-width:1.5px,color:#fff;
    classDef hashicorp fill:#000,stroke:#844FBA,stroke-width:2px,color:#fff;
    classDef tool fill:#f4f4f4,stroke:#333,stroke-width:1px;

    class GitRepo,GHA git;
    class Route53,ACM,ALB,IGW,NAT,ECR aws_blue;
    class ECS aws;
    class TFCloud hashicorp;
    class Slack tool;

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
git commit -m "Add README.md file"
git push origin main

4. Monitor Slack:
The pipeline will notify your Slack channel once the application is live and provide the URL.

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