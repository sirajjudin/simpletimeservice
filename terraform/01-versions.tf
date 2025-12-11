terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.8"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    http = {
      source = "hashicorp/http"
      version = "~> 3.5"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
  }
  backend "s3" {
    bucket = "terraform-on-aws-eks-akshay"
    key    = "dev/eks-cluster/terraform.tfstate"
    region = "ap-south-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
provider "http" {
  # Configuration options
}
provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
