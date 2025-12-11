aws_region = "ap-south-1"
cluster_name = "eks-demo-cluster"
cluster_version = "1.33"
vpc_availability_zones = ["ap-south-1a","ap-south-1b" ]
vpc_public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
vpc_private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
cluster_service_ipv4_cidr = "172.20.0.0/16"
cluster_endpoint_private_access = false
cluster_endpoint_public_access = true

