# Kubernetes Deployment Manifest
resource "kubernetes_deployment_v1" "myapp-sts" {
  depends_on = [ aws_eks_node_group.eks_ng_private ]
  metadata {
    name = "sts-app-deployment"
    labels = {
      app = "sts-app"
    }
    namespace = "default"
  } 
 
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "sts-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "sts-app"
        }
      }

      spec {
        container {
          image = var.deploy_image
          name  = "sts-app"
          port {
            container_port = 80
          }
          }
        }
      }
    }
}

