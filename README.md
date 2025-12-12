# Simple Time Service - AWS EKS Deployment

A containerized Flask application deployed on AWS EKS (Elastic Kubernetes Service) using Terraform for infrastructure as code. This project demonstrates a complete CI/CD pipeline with automated Docker builds, security scanning, and infrastructure provisioning.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Application Details](#application-details)
- [Prerequisites](#prerequisites)
- [Infrastructure Components](#infrastructure-components)
- [Part 1: Manual Deployment](#part-1-manual-deployment)
  - [Step 1: Configure CLI Tools](#step-1-configure-cli-tools)
  - [Step 2: Build and Test Docker Image Locally](#step-2-build-and-test-docker-image-locally)
  - [Step 3: Push Docker Image to Registry](#step-3-push-docker-image-to-registry)
  - [Step 4: Configure Terraform](#step-4-configure-terraform)
  - [Step 5: Deploy Infrastructure & app with Terraform](#step-5-deploy-infrastructure-with-terraform)
  - [Step 6: Access the Application](#step-6-access-the-application)
- [Part 2: CI/CD Pipeline Deployment](#part-2-cicd-pipeline-deployment)
  - [Pipeline Overview](#pipeline-overview)
  - [Pipeline Stages](#pipeline-stages)
  - [Setting Up GitLab CI/CD](#setting-up-gitlab-cicd)
  - [Running the Pipeline](#running-the-pipeline)
- [Security Features](#security-features)
- [Terraform Configuration](#terraform-configuration)
- [Troubleshooting](#troubleshooting)

## Overview

This project implements a **Simple Time Service** that:
- Returns the current timestamp in IST (Indian Standard Time - Asia/Kolkata)
- Displays the client's IP address
- Provides a health check endpoint for monitoring

The application is:
- **Containerized** using Docker with multi-stage builds
- **Deployed** on AWS EKS cluster
- **Exposed** via AWS Application Load Balancer (ALB)
- **Managed** through Terraform for infrastructure provisioning
- **Automated** via GitLab CI/CD pipeline

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitLab CI/CD Pipeline                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Docker Build │→ │ Security Scan│→ │ Terraform    │      │
│  │   & Push     │  │  (Trivy)     │  │ Plan/Apply   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    AWS Infrastructure                        │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │              VPC (ap-south-1)                     │     │
│  │  ┌──────────────┐         ┌──────────────┐        │     │
│  │  │ Public Subnet│         │Private Subnet│        │     │
│  │  │  (10.0.101.x)│         │  (10.0.1.x)  │        │     │
│  │  └──────────────┘         └──────────────┘        │     │
│  │         │                        │                 │     │
│  │         ▼                        ▼                 │     │
│  │  ┌──────────────┐         ┌──────────────┐        │     │
│  │  │  EKS Cluster │         │  Node Group  │        │     │
│  │  │  (Control    │         │  (Workers)   │        │     │
│  │  │   Plane)     │         │              │        │     │
│  │  └──────────────┘         └──────────────┘        │     │
│  └────────────────────────────────────────────────────┘     │
│                            │                                 │
│                            ▼                                 │
│  ┌────────────────────────────────────────────────────┐     │
│  │         Application Load Balancer (ALB)            │     │
│  │         (Internet-facing, Health Checks)          │     │
│  └────────────────────────────────────────────────────┘     │
│                            │                                 │
│                            ▼                                 │
│  ┌────────────────────────────────────────────────────┐     │
│  │         Kubernetes Ingress Resource                │     │
│  │         (AWS Load Balancer Controller)             │     │
│  └────────────────────────────────────────────────────┘     │
│                            │                                 │
│                            ▼                                 │
│  ┌────────────────────────────────────────────────────┐     │
│  │         Simple Time Service Pods                   │     │
│  │         (Flask App on Port 80)                     │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
.
├── app/                                    # Application source code
│   ├── app.py                             # Flask application
│   ├── Dockerfile                         # Multi-stage Docker build
│   └── requirements.txt                   # Python dependencies
│
├── k8s-manifests/                         # Kubernetes manifests (reference)
│   ├── sts-deployment-svc.yml            # Deployment & Service manifests
│   └── sts-ingress.yml                   # Ingress manifest
│
├── terraform/                             # Terraform infrastructure code
│   ├── 01-versions.tf                    # Provider versions & backend config
│   ├── 02-vpc-variables.tf               # VPC input variables
│   ├── 03-vpc-module.tf                  # VPC module configuration
│   ├── 04-vpc-outputs.tf                 # VPC outputs
│   ├── 05-eks-variables.tf               # EKS input variables
│   ├── 06-eks-outputs.tf                 # EKS outputs
│   ├── 07-iamrole-for-eks-cluster.tf     # EKS cluster IAM role
│   ├── 08-iamrole-for-eks-nodegroup.tf   # Node group IAM role
│   ├── 09-securitygroups-eks.tf          # Security groups
│   ├── 10-eks-cluster.tf                 # EKS cluster resource
│   ├── 11-eks-node-group-private.tf      # EKS node group
│   ├── 12-00-irsa.tf                     # IAM Roles for Service Accounts
│   ├── 12-01-lbc-datasources.tf          # Load Balancer Controller data
│   ├── 12-02-lbc-iam-policy-and-role.tf  # LBC IAM policy & role
│   ├── 12-03-lbc-install.tf              # LBC Helm installation
│   ├── 12-04-ingress-class.tf            # Ingress class resource
│   ├── 13-00-variables.tf                # Application variables
│   ├── 13-01-deployment-simple-time-service.tf  # K8s deployment
│   ├── 14-service-np-simple-time-service.tf     # K8s service
│   ├── 15-ingress-simple-time-service.tf        # K8s ingress
│   └── terraform.tfvars                   # Variable values
│
├── .gitlab-ci.yml                        # GitLab CI/CD pipeline
└── README.md                             # This file
```

## 💻 Application Details

### Flask Application (`app/app.py`)

- **Framework**: Flask 2.2.5
- **WSGI Server**: Gunicorn with 2 workers
- **Endpoints**:
  - `GET /` - Returns JSON with IST timestamp and client IP
  - `GET /health` - Health check endpoint (returns "ok")
- **Port**: 80
- **Timezone**: Asia/Kolkata (IST)

### Docker Image

- **Base Image**: Python 3.11-slim
- **Build Strategy**: Multi-stage build for optimized image size
- **Security**:
  - Non-root user execution (UID 1000)
  - Minimal base image
  - Build dependencies removed after installation
- **Image Registry**: Docker Hub (configurable via CI/CD variables)

## 🔧 Prerequisites

### Required Tools

- **Terraform** >= 1.14
  - Installation guide: [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

- **AWS CLI** configured with appropriate credentials
  - Installation guide: [Installing or updating the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

- **kubectl** for Kubernetes cluster interaction
  - Installation guide: [Installing kubectl](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html)

- **Docker** (for local builds)
  - Installation guide: [Install Docker Engine](https://docs.docker.com/engine/install/)

- **Helm** (for managing Kubernetes packages)
  - Installation guide: [Installing Helm](https://helm.sh/docs/intro/install/)

- **GitLab** account with CI/CD enabled (for automated pipeline)
  - **Note**: GitLab Free tier provides 400 minutes per month of CI/CD runner time for pipeline execution

### AWS Requirements

- AWS account with appropriate permissions
- S3 bucket for Terraform state backend (configured in `01-versions.tf`)
- IAM user with programmatic access for Terraform and CI/CD operations

#### Creating IAM User and Security Credentials

Follow these steps to create an IAM user and generate access keys:

1. **Create IAM User**:
   - Log in to AWS Management Console
   - Navigate to **IAM** → **Users** → **Create user**
   - Enter a username (e.g., `terraform-eks-user`)
   - Click **Next**

2. **Attach Permissions**:
   - Select **Attach policies directly**
   - Attach the following AWS managed policies:
     - `AmazonEC2FullAccess` (or more restrictive EC2 permissions)
     - `AmazonVPCFullAccess` (or more restrictive VPC permissions)
     - `IAMFullAccess` (or more restrictive IAM permissions for role creation)
     - `AmazonS3FullAccess` (or more restrictive S3 permissions for state backend)
   - Click **Next** → **Create user**

3. **Create and Attach Inline IAM Policy for EKS**:

   After creating the IAM user, create an inline policy with EKS-specific permissions:

   a. **Navigate to the IAM User**:
      - Go to **IAM** → **Users**
      - Click on the user you just created

   b. **Add Inline Policy**:
      - Click on the **Permissions** tab
      - Scroll down to **Permissions policies** section
      - Click **Add permissions** → **Create inline policy**

   c. **Switch to JSON Editor**:
      - Click on the **JSON** tab
      - Delete any existing content in the editor

   d. **Paste the Policy JSON**:
      Copy and paste the following policy JSON:

      ```json
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Sid": "EKSAdmin",
                  "Effect": "Allow",
                  "Action": [
                      "eks:*"
                  ],
                  "Resource": "*"
              },
              {
                  "Sid": "PassRoleForEKS",
                  "Effect": "Allow",
                  "Action": "iam:PassRole",
                  "Resource": "*",
                  "Condition": {
                      "StringEquals": {
                          "iam:PassedToService": "eks.amazonaws.com"
                      }
                  }
              }
          ]
      }
      ```

   e. **Review and Create Policy**:
      - Click **Next** to review the policy
      - Enter a policy name (e.g., `EKS-Terraform-Policy`)
      - Click **Create policy**

   **Note**: This inline policy provides full EKS permissions and the ability to pass IAM roles to EKS service. It works in conjunction with the managed policies attached in step 2.

4. **Create Security Credentials (Access Keys)**:
   - Select the created IAM user
   - Go to **Security credentials** tab
   - Scroll to **Access keys** section
   - Click **Create access key**
   - Select use case: **Command Line Interface (CLI)** or **Application running outside AWS**
   - Click **Next** → **Create access key**
   - **Important**: Download or copy the **Access Key ID** and **Secret Access Key**
   - Store these credentials securely (you won't be able to view the secret key again)

5. **Configure AWS CLI** (for local development):
   ```bash
   aws configure
   ```
   - Enter your Access Key ID
   - Enter your Secret Access Key
   - Enter default region (e.g., `ap-south-1`)
   - Enter default output format (e.g., `json`)

6. **For GitLab CI/CD**:
   - Add the Access Key ID and Secret Access Key as CI/CD variables:
     - `AWS_ACCESS_KEY_ID` = Your Access Key ID
     - `AWS_SECRET_ACCESS_KEY` = Your Secret Access Key

**Required IAM Permissions Summary**:
- EKS cluster creation and management
- VPC management
- EC2 instance management
- IAM role creation
- S3 access (for state backend)

### Docker Hub Requirements

- Docker Hub account
- Docker Hub access token for authentication (recommended over password)

#### Creating Docker Hub Access Token

Follow these steps to create a Docker Hub access token:

1. **Log in to Docker Hub**:
   - Go to [Docker Hub](https://hub.docker.com/)
   - Sign in with your Docker Hub account

2. **Navigate to Account Settings**:
   - Click on your username in the top right corner
   - Select **Account Settings** from the dropdown menu

3. **Create Access Token**:
   - In the left sidebar, click **Security**
   - Click **New Access Token** button
   - Enter a description for the token (e.g., `terraform-eks-deployment` or `gitlab-ci-cd`)
   - Select permissions:
     - **Read, Write & Delete** (for full access to push/pull images)
     - Or **Read & Write** (for push/pull only)
   - Click **Generate**

4. **Copy and Store Token**:
   - **Important**: Copy the access token immediately
   - Store it securely (you won't be able to view it again)
   - The token will be displayed only once

5. **Use Token for Authentication**:

   **For Local Docker Login**:
   ```bash
   docker login -u <your-dockerhub-username>
   # When prompted for password, enter the access token (not your Docker Hub password)
   ```

   **For GitLab CI/CD**:
   - Use the access token as the value for `DOCKER_PASSWORD` CI/CD variable
   - Username goes in `DOCKER_USERNAME` variable

**Note**: Access tokens are more secure than passwords and can be revoked individually. It's recommended to use tokens instead of passwords for CI/CD pipelines.

### GitLab CI/CD Variables

The following variables need to be configured in GitLab CI/CD settings:

- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub password/token
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_REGION` - AWS region (default: ap-south-1)

## 🏛️ Infrastructure Components

### 1. VPC Configuration

- **Region**: ap-south-1 (Mumbai)
- **Availability Zones**: ap-south-1a, ap-south-1b
- **Public Subnets**: 10.0.101.0/24, 10.0.102.0/24
- **Private Subnets**: 10.0.1.0/24, 10.0.2.0/24
- **Service CIDR**: 172.20.0.0/16

### 2. EKS Cluster

- **Name**: eks-demo-cluster
- **Version**: 1.33
- **Endpoint Access**:
  - Public access: Enabled
  - Private access: Disabled
- **Logging**: Enabled for API, audit, authenticator, controller manager, and scheduler

### 3. EKS Node Group

- **Type**: Managed node group
- **Subnets**: Private subnets
- **Instance Type**: Configured via Terraform variables
- **Scaling**: Configured via Terraform variables

### 4. AWS Load Balancer Controller

- **Installation Method**: Helm chart
- **Purpose**: Manages ALB creation for Kubernetes Ingress resources
- **IRSA**: Uses IAM Roles for Service Accounts for secure AWS API access

### 5. Application Deployment

- **Deployment**: Kubernetes Deployment with 1 replica
- **Service**: NodePort service on port 80
- **Ingress**: ALB Ingress with health checks
- **Health Check Path**: `/health`

---

## Part 1: Manual Deployment

This section covers the manual deployment process where you'll build, push, and deploy the application step-by-step using CLI tools.

### Step 1: Configure CLI Tools

#### 1.1 Configure AWS CLI

After creating IAM user and access keys (see [AWS Requirements](#aws-requirements)), configure AWS CLI:

```bash
aws configure
```

Enter the following when prompted:
- **AWS Access Key ID**: Your IAM user's access key
- **AWS Secret Access Key**: Your IAM user's secret key
- **Default region name**: `ap-south-1` (or your preferred region)
- **Default output format**: `json`

Verify the configuration:
```bash
aws sts get-caller-identity
```

#### 1.2 Configure kubectl

After AWS CLI is configured, set up kubectl to connect to your EKS cluster (after cluster creation):

```bash
aws eks update-kubeconfig --name eks-demo-cluster --region ap-south-1
```

Verify connection:
```bash
kubectl cluster-info
```

#### 1.3 Verify Docker Installation

Ensure Docker is installed and running:

```bash
docker --version
docker ps
```

### Step 2: Build and Test Docker Image Locally

#### 2.1 Build Docker Image

Navigate to the app directory and build the Docker image:

```bash
cd app
docker build -t simple-time-service:local .
```

#### 2.2 Test Docker Image Locally

Run the container locally to test:

```bash
# Give any free host port to run, I am giving 8080
docker run -itd -p 8080:80 --name sts-test simple-time-service:local
```

Test the application:
```bash
# Test main endpoint
curl http://localhost:8080/

# Test health endpoint
curl http://localhost:8080/health
```

Expected response from main endpoint:
```json
{
  "timestamp": "2024-01-15T10:30:45.123456+05:30",
  "ip": "172.17.0.1"
}
```

Stop and remove the test container:
```bash
docker stop sts-test
docker rm sts-test
```

### Step 3: Push Docker Image to Registry

#### 3.1 Login to Docker Hub

```bash
docker login
```

Enter your Docker Hub username and password when prompted.

#### 3.2 Tag and Push Image

Tag the image with your Docker Hub username and version:

```bash
docker tag simple-time-service:local <your-dockerhub-username>/simple-time-service:v1.0.1
docker push <your-dockerhub-username>/simple-time-service:v1.0.1

docker run -itd -p 8080:80 --name sts-test akshayreddy1155/simple-time-service:v1.0.1
docker stop sts-test
docker rm sts-test
```

**Note**: Replace `<your-dockerhub-username>` with your actual Docker Hub username.

### Step 4: Configure Terraform

#### 4.1 Create S3 Bucket for Terraform State

Create an S3 bucket to store Terraform state (if not already created):

**Note**: Bucket names must be globally unique. Change `terraform-on-aws-eks-akshay` to your unique bucket name.

#### 4.2 Update Terraform Configuration

1. **Update Backend Configuration** (if needed):
   - Edit `terraform/01-versions.tf`
   - Update the S3 bucket name, key, and region in the backend block
   - For local testing, you can comment out the entire backend block to store state locally
   - **Note**: State locking using DynamoDB table is deprecated. Use `use_lockfile = true` for enabling state locking

2. **Update Terraform Variables**:
   - Edit `terraform/terraform.tfvars`
   - Update values according to your requirements:
     ```hcl
     aws_region = "ap-south-1"
     cluster_name = "eks-demo-cluster"
     cluster_version = "1.33"
     vpc_availability_zones = ["ap-south-1a", "ap-south-1b"]
     vpc_public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
     vpc_private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
     cluster_service_ipv4_cidr = "172.20.0.0/16"
     cluster_endpoint_private_access = false
     cluster_endpoint_public_access = true
     ```

### Step 5: Deploy Infrastructure & app with Terraform

#### 5.1 Add Helm Repository for AWS Load Balancer Controller

Before initializing Terraform, add the AWS EKS Helm repository which is required for installing the AWS Load Balancer Controller:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
```

Verify the repository was added:
```bash
helm repo list
```

#### 5.2 Initialize Terraform

Navigate to the terraform directory and initialize:

```bash
cd terraform
terraform init
```

This will:
- Download required providers
- Initialize the S3 backend (if configured)
- Set up the working directory

#### 5.3 Create Terraform Plan

Create an execution plan with your Docker image:

```bash
terraform plan 
```

Review the plan to see what resources will be created:
- VPC and subnets
- EKS cluster
- Node groups
- Security groups
- IAM roles
- AWS Load Balancer Controller
- Kubernetes deployment, service, and ingress

#### 5.4 Apply Terraform Configuration

Apply the plan to create all resources:

```bash
terraform apply -auto-approve
```

**Expected Timeline**:
- EKS cluster creation: ~15-20 minutes
- Node group creation: ~5-10 minutes
- ALB provisioning: ~2-5 minutes
- **Total**: ~20-35 minutes

#### 5.5 Configure kubectl for EKS Cluster

After the EKS cluster is created, configure kubectl:

```bash
aws eks update-kubeconfig --name eks-demo-cluster --region ap-south-1
```

Verify cluster access:
```bash
kubectl get nodes
kubectl get pods
```

### Step 6: Access the Application

#### 6.1 Get Load Balancer Hostname

After deployment completes, get the ALB hostname:

```bash
terraform output load_balancer_hostname
```

#### 6.2 Test Application Endpoints

Test the main endpoint:
```bash
curl http://<load-balancer-hostname>/
```

Test the health endpoint:
```bash
curl http://<load-balancer-hostname>/health
```

---

## Part 2: CI/CD Pipeline Deployment

This section covers automated deployment using GitLab CI/CD pipeline, which automates Docker builds, security scanning, and infrastructure deployment.

### Pipeline Overview

The GitLab CI/CD pipeline automates the entire deployment process:

```
Manual Trigger (Web UI)
    ↓
Docker Build & Push
    ↓
Security Scans (Trivy + Terraform)
    ↓
Terraform Plan
    ↓
[Manual Approval Required]
    ↓
Terraform Apply
    ↓
Application Deployed
```

### Pipeline Stages

The pipeline consists of 4 stages executed sequentially:

#### Stage 1: Docker Build and Push

- **Job**: `docker_build_and_push_job`
- **Actions**:
  - Builds Docker image from `./app` directory
  - Tags image with pipeline ID (`$CI_PIPELINE_ID`)
  - Pushes to Docker Hub registry
- **Image**: `docker:latest` with Docker-in-Docker service
- **Output**: Docker image available in registry

#### Stage 2: Security Scan

**Parallel Jobs:**

1. **Trivy Scan** (`trivy_scan`):
   - Scans Docker image for vulnerabilities
   - Severity level: CRITICAL
   - Fails pipeline if critical vulnerabilities found
   - Image: `aquasec/trivy:0.68.1`

2. **Terraform Scan** (`terraform_scan`):
   - Runs `tflint` for Terraform linting
   - Runs `tfsec` for security scanning
   - Allows failure (non-blocking)
   - Image: `alpine:3.18`

#### Stage 3: Terraform Plan

- **Job**: `terraform_plan`
- **Actions**:
  - Initializes Terraform
  - Creates execution plan
  - Passes Docker image tag as variable (`deploy_image`)
  - Saves plan artifact for next stage
- **Image**: `hashicorp/terraform:1.14`
- **Output**: `plan.tfplan` artifact (expires in 1 hour)

#### Stage 4: Terraform Apply

- **Job**: `terraform_apply`
- **Actions**:
  - Applies saved Terraform plan
  - Deploys infrastructure and application
  - Outputs load balancer hostname
- **Image**: `alpine/helm:4.0.1` (with Terraform installed)
- **Trigger**: Manual (requires approval)
- **Dependencies**: Requires `terraform_plan` artifact

### Setting Up GitLab CI/CD

#### 1. Configure GitLab CI/CD Variables

Navigate to your GitLab project:
- Go to **Settings** → **CI/CD** → **Variables**
- Expand **Variables** section
- Add the following variables:

| Variable | Type | Protected | Masked | Description |
|----------|------|-----------|--------|-------------|
| `DOCKER_USERNAME` | Variable | No | No | Docker Hub username |
| `DOCKER_PASSWORD` | Variable | No | Yes | Docker Hub password/token |
| `AWS_ACCESS_KEY_ID` | Variable | No | Yes | AWS IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | Variable | No | Yes | AWS IAM user secret key |
| `AWS_REGION` | Variable | No | No | AWS region (default: `ap-south-1`) |
| `KUBE_CONFIG_DATA` | Variable | No | Yes | Base64-encoded kubeconfig (optional) |

**Security Best Practices**:
- Mark sensitive variables (passwords, keys) as **Masked**
- Mark production variables as **Protected** (only available in protected branches)
- Use Docker Hub access tokens instead of passwords

#### 2. Verify Pipeline Configuration

Ensure `.gitlab-ci.yml` is present in the repository root. The pipeline is configured to:
- Only run on manual trigger via web UI
- Execute on `main` branch for Docker build
- Require manual approval for Terraform apply

### Running the Pipeline

#### 1. Trigger Pipeline Manually

1. Navigate to **Build** → **Pipelines** in your GitLab project
2. Click **Run Pipeline** button
3. Select branch (usually `main`)
4. Click **Run Pipeline**

#### 2. Monitor Pipeline Execution

Watch the pipeline progress through stages:

1. **Docker Build and Push**: 
   - Builds and pushes image to Docker Hub
   - Image tag: `<DOCKER_USERNAME>/simple-time-service:<PIPELINE_ID>`

2. **Security Scans**:
   - Trivy scans the Docker image
   - Terraform scans the infrastructure code
   - Both run in parallel

3. **Terraform Plan**:
   - Creates execution plan
   - Review the plan output in job logs
   - Plan artifact is saved for apply stage

4. **Terraform Apply** (Manual):
   - Job appears with "play" button
   - Click **Play** to approve and execute
   - Monitor logs for deployment progress

#### 3. Get Application URL

After successful deployment:

1. Check pipeline job output for `load_balancer_hostname`
2. Or run in GitLab CI/CD job:
   ```bash
   terraform output load_balancer_hostname
   ```

#### 4. Verify Deployment

Test the deployed application:
```bash
# Main endpoint
curl http://<load-balancer-hostname>/

# Health endpoint
curl http://<load-balancer-hostname>/health
```

### Pipeline Configuration Details

The pipeline configuration (`.gitlab-ci.yml`) includes:

- **Workflow Rules**: Only runs on manual web trigger
- **Docker-in-Docker**: Enabled for Docker builds
- **Artifact Management**: Terraform plan saved between stages
- **Security Scanning**: Integrated Trivy and Terraform security tools
- **Manual Gates**: Terraform apply requires manual approval
- **Error Handling**: Proper error handling and logging

## 🔒 Security Features

### Application Security

- **Non-root User**: Container runs as non-root user (UID 1000)
- **Minimal Base Image**: Uses Python slim image
- **Multi-stage Build**: Removes build dependencies from final image
- **Security Scanning**: Trivy scans images for vulnerabilities

### Infrastructure Security

- **Private Node Groups**: Worker nodes in private subnets
- **IAM Roles for Service Accounts (IRSA)**: Secure AWS API access
- **Security Groups**: Restrictive firewall rules
- **Terraform Security Scanning**: `tflint` and `tfsec` checks
- **EKS Control Plane Logging**: Comprehensive audit logging enabled

### Network Security

- **Private Subnets**: Application pods run in private subnets
- **Public ALB**: Only ALB is internet-facing
- **Health Checks**: ALB health checks configured for reliability

## 📝 Terraform Configuration

### Backend Configuration

Terraform state is stored in S3 with the following configuration:
- **Bucket**: `terraform-on-aws-eks-akshay`
- **Key**: `dev/eks-cluster/terraform.tfstate`
- **Region**: `ap-south-1`
- **State Locking**: Enabled

### Key Variables

Configure in `terraform/terraform.tfvars`:

```hcl
aws_region = "ap-south-1"
cluster_name = "eks-demo-cluster"
cluster_version = "1.33"
vpc_availability_zones = ["ap-south-1a", "ap-south-1b"]
vpc_public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
vpc_private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
cluster_service_ipv4_cidr = "172.20.0.0/16"
cluster_endpoint_private_access = false
cluster_endpoint_public_access = true
```

### Terraform Providers

- **AWS Provider**: ~> 6.8
- **Kubernetes Provider**: ~> 2.38
- **Helm Provider**: 3.0.2
- **HTTP Provider**: ~> 3.5

## 🐛 Troubleshooting

### Common Issues

#### 1. Terraform Backend Error
**Problem**: Cannot access S3 backend
**Solution**: 
- Ensure S3 bucket exists
- Verify AWS credentials have S3 permissions
- Check bucket region matches configuration

#### 2. EKS Cluster Creation Fails
**Problem**: IAM role permissions insufficient
**Solution**:
- Verify IAM roles have required EKS policies attached
- Check CloudFormation events for specific errors

#### 3. Pods Not Starting
**Problem**: Image pull errors or node capacity
**Solution**:
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

#### 4. ALB Not Created
**Problem**: AWS Load Balancer Controller not working
**Solution**:
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
kubectl describe ingress ingress-sts-app
```

#### 5. Health Check Failures
**Problem**: ALB health checks failing
**Solution**:
- Verify `/health` endpoint is accessible
- Check security group rules allow traffic
- Verify service and deployment are running

### Useful Commands

**Check EKS Cluster Status:**
```bash
aws eks describe-cluster --name eks-demo-cluster --region ap-south-1
```

**Get Kubernetes Context:**
```bash
aws eks update-kubeconfig --name eks-demo-cluster --region ap-south-1
```

**View Pods:**
```bash
kubectl get pods -l app=sts-app
```

**View Services:**
```bash
kubectl get svc
```

**View Ingress:**
```bash
kubectl get ingress
kubectl describe ingress ingress-sts-app
```

**View Logs:**
```bash
kubectl logs -l app=sts-app
```

## 📊 Monitoring and Maintenance

### Health Checks

The application includes a health check endpoint at `/health` that:
- Returns HTTP 200 status
- Used by ALB for target health monitoring
- Configured with 15-second intervals

### Logging

- **Application Logs**: Access via `kubectl logs`
- **EKS Control Plane Logs**: Enabled in CloudWatch
- **ALB Access Logs**: Can be enabled via Terraform

### Scaling

To scale the application:
1. Update `replicas` in `terraform/13-01-deployment-simple-time-service.tf`
2. Run `terraform apply`

Or manually:
```bash
kubectl scale deployment sts-app-deployment --replicas=3
```

## 🧹 Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy
```

**Note**: This will delete:
- EKS cluster and node groups
- VPC and networking resources
- Load balancer and ingress
- All Kubernetes resources
