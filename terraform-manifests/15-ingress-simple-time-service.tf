# Kubernetes Service Manifest (Type: Load Balancer)
resource "kubernetes_ingress_v1" "ingress" {
  depends_on = [ kubernetes_ingress_class_v1.ingress_class_default, kubernetes_service_v1.sts_service ]
  metadata {
    name = "ingress-sts-app"
    annotations = {
      # Load Balancer Name
      "alb.ingress.kubernetes.io/load-balancer-name" = "ingress-sts-app"
      # Ingress Core Settings
      "alb.ingress.kubernetes.io/scheme" = "internet-facing"
      # Health Check Settings
      "alb.ingress.kubernetes.io/healthcheck-protocol" =  "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-port" = "traffic-port"
      #Important Note:  Need to add health check path annotations in service level if we are planning to use multiple targets in a load balancer    
      "alb.ingress.kubernetes.io/healthcheck-path" =  "/health"
      "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = 15
      "alb.ingress.kubernetes.io/healthcheck-timeout-seconds" = 5
      "alb.ingress.kubernetes.io/success-codes" = 200
      "alb.ingress.kubernetes.io/healthy-threshold-count" = 2
      "alb.ingress.kubernetes.io/unhealthy-threshold-count" = 2
    }    
  }

  spec {
    ingress_class_name = "my-aws-ingress-class" # Ingress Class            
    default_backend {
      service {
        name = kubernetes_service_v1.sts_service.metadata[0].name
        port {
          number = 80
        }
      }
    }
  }
}
output "sts_alb_dns_name" {
  description = "DNS name of the AWS Application Load Balancer created for the simple time service"
  value       = kubernetes_ingress_v1.ingress.status[0].load_balancer[0].ingress[0].hostname
}

output "alb_url" {
  description = "Public URL to reach the STS app via HTTP"
  value       = "http://${kubernetes_ingress_v1.ingress.status[0].load_balancer[0].ingress[0].hostname}"
}



