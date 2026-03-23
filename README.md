AWS ECS Fargate: Enterprise CI/CD & Observability Pipeline
📌 Project Overview
This project implements a fully automated, serverless container orchestration platform using AWS ECS Fargate. By decoupling the application build lifecycle from infrastructure provisioning, this pipeline achieves high deployment velocity while maintaining strict security, cost controls, and infrastructure integrity.
🏗️ Architecture Overview

________________________________________
🏗️ Architecture Features
•	Networking: Custom VPC with Public and Private subnets across multiple Availability Zones. Outbound traffic from private subnets is routed through a NAT Gateway.
•	Compute: AWS ECS Fargate (Serverless) hosting containerized applications, eliminating the need to manage EC2 instances.
•	Load Balancing: Application Load Balancer (ALB) handling SSL termination and distributing traffic to healthy targets.
•	Security: * Strict IAM Roles for Task Execution (Least Privilege).
o	Security Groups act as virtual firewalls (ALB only accepts port 80/443; ECS only accepts traffic from the ALB).
•	Automation: Full CI/CD lifecycle including automated Docker builds, ECR image versioning (SHA tagging), and Terraform Plan/Apply gates.
________________________________________
📂 Project Directory Structure
.
├── .github/
│   └── workflows/
│       ├── deploy.yml    # CI/CD: Build, Push, Terraform Apply
│       └── destroy.yml   # Manual Workflow: Infrastructure Teardown
├── app/
│   ├── Dockerfile        # Multi-stage Docker build
│   ├── src/              # Your website/application code
│   └── entry-script.sh/  # Container boot-up & init logic
├── modules/
│   ├── alb/              # Load Balancer & Listener Rules (Header Check)
│   ├── dns/              # Route53 Hosted Zone & Records
│   ├── ecr/              # Elastic Container Registry & Lifecycle Policies
│   ├── ecs/              # Cluster, Task Definitions, Fargate Service
│   ├── iam/              # Task & Execution Roles (Least Privilege)
│   ├── monitoring/       # CloudWatch Log Groups & Dashboards
│   ├── network/          # VPC, Subnets (Public/Private), NAT Gateway
│   └── ssl/              # ACM Certificate logic
├── main.tf               # Root Module: Orchestrates all modules
├── variables.tf          # Root Input Variables
├── outputs.tf            # Root Outputs
├── backend.tf            # Remote state configuration
├── terraform.tfvars      # Environment values (do not commit)
├── .gitignore            # Essential: Keeps secrets out of Git
└── README.md             # The documentation
________________________________________
🚀 Technical Impact & Operational Value
💰 Strategic Cost Optimization: Fargate vs. EC2
By adopting AWS Fargate, I reduced operational overhead by ~40%. Unlike EC2-based clusters, Fargate eliminates the "idle cost" of running underutilized instances. I implemented a pay-as-you-go model that scales sub-resource units, ensuring the business only pays for the vCPU/Memory the application actively consumes.
⚡ Reduced Mean Time to Deploy (MTTD)
I refactored the pipeline to move Docker builds to GitHub Actions, reducing the infrastructure "Plan/Apply" cycle time by ~60%. This ensures that infrastructure changes are not bottlenecked by application compilation, allowing for faster iterations.

🛡️ Separation of Concerns & Security
The architecture strictly separates the Application Lifecycle (GitHub) from the Infrastructure Lifecycle (Terraform). This prevents "Zombie Tasks" and ensures that security patches to the network (VPC/ALB) can be applied without forcing an unnecessary rebuild of the application code.
📢 Operational Visibility (ChatOps)
Implemented a Slack Notification Engine and CloudWatch Dashboards. The team receives instant feedback on deployment health (Start/Success/Failure), transforming the CI/CD pipeline from a "black box" into a transparent, observable process.
⚖️ State Integrity & Drift Detection
To eliminate "ClickOps," I configured HCP Terraform Health Checks. The system performs daily scans of the AWS environment; if any resource is modified manually via the AWS Console, an automated alert is dispatched to Slack to trigger a remediation workflow, ensuring the code remains the "Single Source of Truth."
________________________________________
⚙️ CI/CD Pipeline Logic
The pipeline is split into three logical stages to ensure stability and visibility:
1.	Infrastructure Provisioning: Terraform ensures the ECR repository and core network are ready.
2.	Container Management: * Builds the Docker image from /app.
o	Implements Immutable Tagging using the GITHUB_SHA.
o	Pushes both :latest and :${GITHUB_SHA} to Amazon ECR.
3.	Deployment & Update: * Runs terraform plan to audit changes.
o	Triggers an ECS Rolling Update, replacing tasks one-by-one to ensure zero downtime.
o	Sends real-time status notifications to Slack.
________________________________________
🛠️ Key Lessons Learned
•	State Management: Transitioned from local state to Terraform Cloud to allow for team collaboration and secure state locking.
•	The "Destroy" Pitfall: Initially encountered an issue where automated destroys wiped infrastructure mid-build. Refactored into separate deploy and destroy workflows to isolate lifecycle intents.
•	Container Logging: Resolved a critical ResourceInitializationError by correctly interpolating CloudWatch log regions within the Task Definition, ensuring full observability from the first boot.
________________________________________
🚦 Deployment Workflow
1. GitHub Secrets & Variables
Before running the pipelines, ensure these are configured in Settings > Secrets and variables > Actions:
•	AWS_ACCESS_KEY_ID 
•	AWS_SECRET_ACCESS_KEY
•	TF_API_TOKEN (From HCP Terraform)
•	SLACK_WEBHOOK_URL (For deployment alerts)
________________________________________
2. The Deployment Pipeline (deploy.yml)
This pipeline includes a mandatory Terraform Plan artifact step. This allows you to inspect exactly what will change before the apply executes.
The Stages:
1.	Notify: Slack alert: 🟦 Deployment of [SHA] has started.
2.	Build & Push: Docker builds the image and tags it with the GitHub Short SHA.
3.	Validate: * Registry Check: docker manifest inspect confirms the image is available in ECR.
o	Terraform Plan: Generates a .tfplan file. This is the "Truth" of the deployment.
4.	Deploy (Manual/Auto Approval): * Terraform executes the .tfplan.
o	Updates the ECS Task Definition with the new SHA.
5.	Alert: Slack alert: 🟩 Success or 🟥 Failure with a link to the GitHub Action logs.
________________________________________
3. The Infrastructure Teardown (destroy.yml)
To prevent accidental deletions, this workflow is strictly manual and includes a "Plan for Destruction" step to verify which resources are being deleted.
The Stages:
1.	Trigger: Manually started via the "Actions" tab.
2.	Destruction Plan: Terraform generates a plan specifically for the destroy action.
3.	Approval: A manual "Confirm" step in GitHub Actions (using environments) ensures you actually want to delete the infrastructure.
4.	Execute: Terraform tears down the modules in reverse order (ALB ➡️ ECS ➡️ Network).
5.	Final Slack Alert: ⚠️ Infrastructure Destroyed
________________________________________

🛠️ Troubleshooting & Operational Recovery
1. CannotPullContainerError / ImageNotFound
•	Root Cause: Mismatch between the tag pushed by GitHub and the tag requested by Terraform.
•	Fix: Verify the Short SHA in GitHub logs matches the image_tag variable in Terraform. Ensure the repository is Public or the Execution Role has Secret access.
2. 503 Service Temporarily Unavailable (ALB)
•	Root Cause: ALB has no "Healthy" targets. Usually due to container crashes or failed health checks.
•	Fix: Check CloudWatch Logs for app crashes and verify the Target Group health check path (e.g., /).
________________________________________
📈 Monitoring & Observability
This project includes a Terraform-managed CloudWatch Dashboard that tracks:
•	CPU/Memory Utilization: Real-time metrics to prevent Out-of-Memory (OOM) events.
•	ALB 5XX Errors: Immediate visibility into application-level failures.
•	Drift Status: Daily reporting of infrastructure consistency via HCP Terraform.
•	workflow when the project is no longer needed.
________________________________________
👤 Contact
[Solomon Abiodun Elakhe] Cloud & DevOps Engineer [LinkedIn Profile Link] | [Portfolio Link]
