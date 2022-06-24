resource "helm_release" "csi" {
  depends_on = [
    aws_eks_cluster.this
  ]
  name       = "aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  version    = "2.2.7"
  namespace  = "kube-system"

  values = [
    <<-EOF
    image:
        repository: 602401143452.dkr.ecr.eu-central-1.amazonaws.com/eks/aws-efs-csi-driver
    controller:
        serviceAccount:
            annotations:
                eks.amazonaws.com/role-arn: ${aws_iam_role.csi[0].arn}
    EOF
  ]
}