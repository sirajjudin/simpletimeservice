# Simple Time Service - AWS EKS Deployment

A containerized Flask application deployed on AWS EKS (Elastic Kubernetes Service) using Terraform for infrastructure as code. This project demonstrates a complete CI/CD pipeline with automated Docker builds, security scanning, and infrastructure provisioning.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Application Details](#application-details)
- [Prerequisites](#prerequisites)
- [Infrastructure Components](#infrastructure-components)
- [CI/CD Pipeline](#cicd-pipeline)
- [Deployment Instructions](#deployment-instructions)
- [Accessing the Application](#accessing-the-application)
- [Security Features](#security-features)
- [Terraform Configuration](#terraform-configuration)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

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

## 🏗️ Architecture

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
- **AWS CLI** configured with appropriate credentials
- **kubectl** for Kubernetes cluster interaction
- **Docker** (for local builds)
- **GitLab** account with CI/CD enabled (for automated pipeline)

### AWS Requirements

- AWS account with appropriate permissions
- S3 bucket for Terraform state backend (configured in `01-versions.tf`)
- IAM permissions for:
  - EKS cluster creation
  - VPC management
  - EC2 instance management
  - IAM role creation
  - S3 access (for state backend)

### GitLab CI/CD Variables

The following variables need to be configured in GitLab CI/CD settings:

- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub password/token
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_REGION` - AWS region (default: ap-south-1)
- `KUBE_CONFIG_DATA` - Base64-encoded kubeconfig (optional, for kubectl operations)

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

## 🔄 CI/CD Pipeline

The GitLab CI/CD pipeline consists of 4 stages:

### Stage 1: Docker Build and Push

- Builds Docker image from `./app` directory
- Tags image with pipeline ID
- Pushes to Docker Hub registry

### Stage 2: Security Scan

**Parallel Jobs:**
- **Trivy Scan**: Scans Docker image for vulnerabilities (CRITICAL severity)
- **Terraform Scan**: Runs `tflint` and `tfsec` on Terraform code

### Stage 3: Terraform Plan

- Initializes Terraform
- Creates execution plan
- Passes Docker image tag as variable
- Saves plan artifact for next stage

### Stage 4: Terraform Apply

- **Manual Trigger**: Requires manual approval
- Applies Terraform plan
- Deploys infrastructure and application
- Outputs load balancer hostname

### Pipeline Workflow

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

## 🚀 Deployment Instructions

### Option 1: Automated Deployment via GitLab CI/CD

1. **Configure GitLab CI/CD Variables**:
   - Navigate to GitLab project → Settings → CI/CD → Variables
   - Add all required variables (see Prerequisites section)

2. **Trigger Pipeline**:
   - Go to CI/CD → Pipelines
   - Click "Run Pipeline" (manual trigger via web UI)
   - Pipeline will build, scan, plan, and wait for manual approval

3. **Approve Deployment**:
   - After Terraform plan completes, manually approve the `terraform_apply` job
   - Monitor the pipeline for completion

4. **Get Application URL**:
   - After successful deployment, check Terraform outputs for `load_balancer_hostname`
   - Or run: `terraform output load_balancer_hostname` in the terraform directory

### Option 2: Manual Deployment

1. **Build and Push Docker Image**:
   ```bash
   cd app
   docker build -t <your-dockerhub-username>/simple-time-service:v1.0.1 .
   docker login
   docker push <your-dockerhub-username>/simple-time-service:v1.0.1
   # Give a free port on a server to run the container
   docker run -itd -p <host-port>:80 --name sts <your-dockerhub-username>/simple-time-service:v1.0.1
   http://<server-ip>:<host-port>
   ```

2. **Configure Terraform Variables**:
   - Update `terraform/terraform.tfvars` with your values
   - Ensure S3 backend bucket exists (configured in `01-versions.tf`)
   - Change the bucket, key and region to store state and lock file remotely, for testing purpose you can comment entire backend block if you want to store state locally. state locking using dynamodb table is deprecated, we have to give use_lockfile = true for enabling state locking.


3. **Initialize and Apply Terraform**:
   ```bash
   cd terraform
   terraform init
   terraform plan -var "deploy_image=<your-dockerhub-username>/simple-time-service:v1.0.1"
   terraform apply
   ```

4. **Wait for Resources**:
   - EKS cluster creation: ~15-20 minutes
   - Node group creation: ~5-10 minutes
   - ALB provisioning: ~2-5 minutes

5. **Get Application URL**:
   ```bash
   terraform output load_balancer_hostname
   ```

## 🌐 Accessing the Application

After successful deployment, access the application using the ALB hostname:

### Main Endpoint
```bash
curl http://<load-balancer-hostname>/
```

**Response:**
```json
{
  "timestamp": "2024-01-15T10:30:45.123456+05:30",
  "ip": "203.0.113.1"
}
```

### Health Check Endpoint
```bash
curl http://<load-balancer-hostname>/health
```

**Response:**
```
ok
```

### Get Load Balancer Hostname

**Via Terraform:**
```bash
cd terraform
terraform output load_balancer_hostname
```

**Via kubectl:**
```bash
kubectl get ingress ingress-sts-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

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
