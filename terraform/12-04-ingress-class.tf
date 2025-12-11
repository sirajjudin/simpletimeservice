# Resource: Kubernetes Ingress Class
resource "kubernetes_ingress_class_v1" "ingress_class_default" {
  depends_on = [helm_release.loadbalancer_controller,aws_iam_role.lbc_iam_role,
  aws_iam_role_policy_attachment.lbc_iam_role_policy_attach]
  metadata {
    name = "my-aws-ingress-class"
    annotations = {
      "ingressclass.kubernetes.io/is-default-class" = "true"
    }
  }  
  spec {
    controller = "ingress.k8s.aws/alb"
  }
}