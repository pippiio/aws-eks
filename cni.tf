resource "helm_release" "vpc_cni" {
  depends_on = [
    aws_eks_cluster.this
  ]
  name       = "aws-vpc-cni"
  chart      = "aws-vpc-cni"
  repository = "https://aws.github.io/eks-charts"
  version    = "1.1.17"
  namespace  = "kube-system"

  set {
    name  = "crd.create"
    value = false
  }

  set {
    name  = "originalMatchLabels"
    value = true
  }

  set {
    name  = "env.ENABLE_PREFIX_DELEGATION"
    value = true
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-vpc-cni"
  }

  set {
    name  = "init.image.region"
    value = local.region_name
  }
}