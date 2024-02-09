locals {
  addons = tomap(var.addons)
}

data "aws_eks_addon_version" "this" {
  for_each = { for name, enable in local.addons : name => enable if enable }

  addon_name         = each.key
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = false
}

resource "aws_eks_addon" "this" {
  for_each = { for name, enable in local.addons : name => enable if enable }

  addon_name    = each.key
  cluster_name  = aws_eks_cluster.this.name
  addon_version = data.aws_eks_addon_version.this[each.key].version

  tags = local.default_tags
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  count = var.addons.vpc-cni ? 1 : 0

  role       = aws_iam_role.node_group.name
  policy_arn = data.aws_iam_policy.AmazonEBSCSIDriverPolicy.arn
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  count = var.addons.aws-ebs-csi-driver ? 1 : 0

  role       = aws_iam_role.node_group.name
  policy_arn = data.aws_iam_policy.AmazonEBSCSIDriverPolicy.arn
}

data "aws_iam_policy" "AmazonEKS_CNI_Policy" {
  name = "AmazonEKS_CNI_Policy"
}

data "aws_iam_policy" "AmazonEBSCSIDriverPolicy" {
  name = "AmazonEBSCSIDriverPolicy"
}




# data "aws_iam_policy_document" "csi" {
#   statement {
#     actions = [
#       "elasticfilesystem:DescribeAccessPoints",
#       "elasticfilesystem:DescribeFileSystems",
#       "elasticfilesystem:DescribeMountTargets",
#       "ec2:DescribeAvailabilityZones",
#     ]
#     resources = ["*"]
#   }
#   statement {
#     actions = [
#       "elasticfilesystem:CreateAccessPoint",
#     ]
#     resources = ["*"]
#     condition {
#       test     = "StringLike"
#       variable = "aws:RequestTag/efs.csi.aws.com/cluster"

#       values = [
#         "true",
#       ]
#     }
#   }
#   statement {
#     actions = [
#       "elasticfilesystem:DeleteAccessPoint",
#     ]
#     resources = ["*"]
#     condition {
#       test     = "StringLike"
#       variable = "aws:ResourceTag/efs.csi.aws.com/cluster"

#       values = [
#         "true",
#       ]
#     }
#   }
# }

# data "aws_iam_policy_document" "csi_assume" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
#     }

#     principals {
#       identifiers = [aws_iam_openid_connect_provider.this.arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "csi" {
#   count = local.config.efs_enabled ? 1 : 0

#   name = "${local.name_prefix}efs-csi"

#   assume_role_policy = data.aws_iam_policy_document.csi_assume.json

#   inline_policy {
#     name   = "csi-policy"
#     policy = data.aws_iam_policy_document.csi.json
#   }
# }