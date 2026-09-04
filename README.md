                                                                                      DevOps Tech Challenge

React + Express application deployed to AWS ECS Fargate, fully provisioned with Terraform, with dual CI/CD pipelines (Jenkins and GitHub Actions).

## 📐 Architecture Overview

Below is the workflow showing how **Terraform** provisions resources inside **AWS** via **GitHub Actions**:

<p align="center">
  <img src="/Users/Admin/home/1percent/tech_challenge1/devops-code-challenge1A/devops-code-challenge1/README.svg" width="700">
</p>


### 🛠️ Tech Stack & Tools

<p align="left">
  <a href="https://aws.amazon.com/" target="_blank" rel="noreferrer">
    <img src="https://skillicons.dev" alt="My Tech Stack" />
  </a>
</p>


</div>
Table of contents
Overview
Live environment
Architecture
Repository structure
Branch strategy
Prerequisites
Local development
Infrastructure deployment
CI/CD — Jenkins
CI/CD — GitHub Actions
Load testing & auto scaling validation
Issues found and fixed
Security
Submission
Overview

This project provisions a complete, production-style AWS environment for a containerized React frontend and Express backend, then automates every step of building, testing, and deploying that environment through two independent, fully working CI/CD pipelines.

All infrastructure — networking, load balancing, container orchestration, auto scaling, IAM, and the CI/CD servers themselves — is defined as code in Terraform. No resources were created manually through the AWS Console.

Live environment
http://devops-challenge-alb-1970167075.us-east-1.elb.amazonaws.com

Infrastructure is stopped between demo sessions to control cost. If the link above isn't responding, the environment may need to be started — see Infrastructure deployment.

Architecture

Show Image

Layer	Service	Details
Networking	VPC	2 public + 2 private subnets across 2 Availability Zones
Networking	Internet Gateway / NAT Gateway	Public subnets reach the internet directly; private subnets route outbound traffic through NAT
Edge	Application Load Balancer	Routes / to the frontend target group, /api and /api/* to the backend target group
Compute	ECS Fargate	Two services, private subnets, no public IPs assigned
Compute	Frontend service	devops-challenge-frontend_service — React app via serve -s build, port 3000
Compute	Backend service	devops-challenge-backend-service — Express API, port 8080
Registry	ECR	Two repositories (frontend/backend), image scanning on push, retains 5 most recent tags
Scaling	Application Auto Scaling	Target tracking on CPU utilization, 50% threshold, min 1 / desired 1 / max 4 tasks
IAM	Task execution + task roles	Execution role pulls images and writes logs; task role scoped to app-level permissions
Observability	CloudWatch Logs	One log group per service
CI/CD infra	Jenkins on EC2	Self-managed, running in Docker, provisioned via Terraform + Ansible
Repository structure
.
├── backend/                        # Express API
├── frontend/                       # React app
├── terraform/                      # All infrastructure as code
│   ├── vpc.tf
│   ├── sg.tf
│   ├── alb.tf
│   ├── ecs.tf
│   ├── ecr.tf
│   ├── asg.tf                      # Auto scaling target + policy
│   ├── jenkins.tf                  # Jenkins + Ansible control node EC2s
│   ├── s3.tf                       # Remote state backend
│   ├── outputs.tf
│   ├── playbook.yaml               # Ansible playbook for Jenkins EC2 setup
│   └── inventory.ini
├── Jenkinsfile                     # CI/CD pipeline (main branch)
├── .github/workflows/deploy.yaml   # CI/CD pipeline (gitops branch only)
├── keyscan.sh                      # Git history secret-scanning script
└── README.md
Branch strategy
Branch	Purpose
main	Primary submission. Infrastructure via Terraform; CI/CD via a self-hosted Jenkins server on EC2.
gitops	Bonus, GitOps-style CI/CD using GitHub Actions instead of Jenkins.

Both branches deploy to the same ECS cluster and services — there is a single live environment, and whichever pipeline ran most recently is what's currently deployed.

Prerequisites
AWS CLI configured with credentials that have ECS, ECR, EC2, VPC, and IAM permissions
Terraform >= 1.x
Docker
Node.js 16 (matches the Docker base image; newer versions can trigger an OpenSSL/Webpack build error in the frontend)
Local development
bash
# Backend
cd backend
npm ci
npm start          # localhost:8080

# Frontend
cd frontend
npm install
npm start           # localhost:3000, calls localhost:8080

Or containerized:

bash
docker build -t backend-app ./backend
docker run -p 8080:8080 backend-app

docker build -t frontend-app ./frontend
docker run -p 3000:3000 frontend-app
Infrastructure deployment (Terraform)
bash
cd terraform
terraform init
terraform plan
terraform apply

This provisions the VPC, ALB, ECS cluster/services/task definitions, ECR repositories, IAM roles, Auto Scaling policies, and the Jenkins/Ansible EC2 instances.

Two lifecycle protections are in place and worth understanding before running terraform apply again:

aws_ecs_service.frontend_ecs_service and .backend_ecs_service — lifecycle { ignore_changes = [task_definition] }. Both CI/CD pipelines register new task definition revisions directly via the AWS CLI, outside Terraform's knowledge. Without this, a routine terraform apply would silently roll each service back to whatever revision Terraform last recorded, undoing the latest deployment.
aws_instance.jenkins_master and .ansible_master — lifecycle { ignore_changes = [ami] }. The AMI is resolved dynamically via a most_recent = true data source, which can return a different AMI ID as AWS publishes updates. Without this, that drift would force a full destroy-and-recreate of the Jenkins server on the next apply.
CI/CD — Jenkins (main branch)

Jenkins runs in a Docker container on an EC2 instance, provisioned via Terraform and configured with Ansible. The Jenkinsfile pipeline triggers on every push to main via a GitHub webhook:

Checkout — pulls the latest code
Build Docker images — builds frontend and backend images, tagged with the Jenkins build number
Push to ECR — authenticates via aws ecr get-login-password, pushes both images
Register new ECS task definitions — pulls the current task definition, swaps in the new image with jq, registers a new revision
Update ECS services — triggers a rolling deployment to the new revision with zero downtime
CI/CD — GitHub Actions (gitops branch, bonus)

A parallel, GitOps-style pipeline (.github/workflows/deploy.yaml), triggered on every push to gitops. Functionally identical to the Jenkins pipeline (build → push → register → deploy), but runs on GitHub-hosted runners instead of a self-managed EC2 server, with credentials stored as encrypted GitHub Actions secrets rather than in a Jenkins credential store.

Both pipelines were run end-to-end and independently verified via aws ecs describe-services, each producing a new, distinct task definition revision on the live cluster.

Load testing & auto scaling validation

Load tested with siege against the live frontend URL to confirm the CPU-based scaling policy actually triggers under load, not just that it's configured:

bash
siege -c 50 -t 3M http://devops-challenge-alb-1970167075.us-east-1.elb.amazonaws.com/
Metric	Result
Total requests	8,819
Availability	99.93%
Failed transactions	6
Elapsed time	180.53s
Concurrency	49.29

The application remained responsive throughout, with no meaningful downtime.

Scaling confirmed via AWS's own CloudWatch alarm history (ECS service Events tab), not just Terraform config:

Scale-out: Successfully set desired count to 2 ... monitor alarm ...-AlarmHigh-... in state ALARM triggered policy devops-challenge-frontend-cpu-policy
Scale-in (after load stopped): Successfully set desired count to 1 ... monitor alarm ...-AlarmLow-... in state ALARM triggered policy devops-challenge-frontend-cpu-policy

Both are timestamped, AWS-generated audit log entries, confirming the full scale-out-then-scale-in lifecycle.

Notable issues found and fixed during deployment
Issue	Root cause	Fix
API calls returned index.html instead of JSON	ALB listener rule matched /api/* only, which doesn't match a bare /api path	Broadened path_pattern.values to ["/api", "/api/*"]
Frontend tasks stuck in a pull-failure crash loop	frontend_sg had no egress block, which strips Terraform's default allow-all-outbound rule	Added an explicit egress rule
Frontend showed stale/wrong API URL after deploy	Create React App bakes REACT_APP_*/imported config values into the JS bundle at docker build time, not at container runtime	Updated frontend/src/config.js and rebuilt the image
Security
AWS credentials for both Jenkins and GitHub Actions are stored as encrypted secrets, never committed to the repository
.gitignore excludes Terraform state files, .tfvars, and .env files
Full git history (git log --all -p, across every branch) was scanned for exposed private keys and AWS access key IDs — none were found. The scan script (keyscan.sh) is included in the repo and can be re-run at any time with bash keyscan.sh
Submission

Repository access will be granted to the grader at the email address provided in the challenge instructions.

<div align="center"> <sub>Screenshots (pipeline runs, live app, load test output) can be added under an <code>images/</code> folder and referenced with <code>![caption](images/filename.png)</code>.</sub> </div>
