# Kubernetes Service Manifest (Type: Node Port Service)
resource "kubernetes_service_v1" "sts_service" {
  depends_on = [ kubernetes_deployment_v1.myapp-sts ]
  metadata {
    name = "sts-app-nodeport-service" 
    namespace = "default"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.myapp-sts.spec.0.selector.0.match_labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}