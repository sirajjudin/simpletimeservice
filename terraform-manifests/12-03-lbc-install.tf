# Install AWS Load Balancer Controller using HELM

# Map of AWS regions to ECR account IDs
locals {
  lbc_ecr_account_map = {
    # US regions
    "us-east-1" = "602401143452"
    "us-east-2" = "602401143452"
    "us-west-1" = "602401143452"
    "us-west-2" = "602401143452"

    # Canada
    "ca-central-1" = "602401143452"

    # South America
    "sa-east-1" = "602401143452"

    # Europe
    "eu-central-1" = "602401143452"
    "eu-west-1"    = "602401143452"
    "eu-west-2"    = "602401143452"
    "eu-west-3"    = "602401143452"
    "eu-north-1"   = "602401143452"
    "eu-south-1"   = "590381155156" # Milan
    "eu-central-2" = "900612956339" # Zurich
    "eu-south-2"   = "557608235920" # Spain

    # Africa
    "af-south-1" = "877085696533" # Cape Town

    # Middle East
    "me-south-1"   = "558608220178" # Bahrain
    "me-central-1" = "759879836304" # UAE

    # Asia Pacific
    "ap-south-1"     = "602401143452" # Mumbai
    "ap-south-2"     = "900612956339" # Hyderabad
    "ap-northeast-1" = "602401143452" # Tokyo
    "ap-northeast-2" = "602401143452" # Seoul
    "ap-northeast-3" = "602401143452" # Osaka
    "ap-east-1"      = "800184023465" # Hong Kong
    "ap-southeast-1" = "602401143452" # Singapore
    "ap-southeast-2" = "602401143452" # Sydney
    "ap-southeast-3" = "296578399912" # Jakarta
    "ap-southeast-4" = "347163612497" # Melbourne
  }

  lbc_image_repo = "${local.lbc_ecr_account_map[var.aws_region]}.dkr.ecr.${var.aws_region}.amazonaws.com/amazon/aws-load-balancer-controller"
}

# Resource: Helm Release
resource "helm_release" "loadbalancer_controller" {
  depends_on = [aws_iam_role.lbc_iam_role]
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    yamlencode({
      image = {
        repository = local.lbc_image_repo
      }

      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.lbc_iam_role.arn
        }
      }
      vpcId       = module.vpc.vpc_id
      region      = var.aws_region
      clusterName = aws_eks_cluster.eks_cluster.id
    })
  ]
}


output "lbc_helm_metadata" {
  description = "Metadata Block outlining status of the deployed release."
  value       = helm_release.loadbalancer_controller.metadata
}

