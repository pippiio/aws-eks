data "aws_iam_policy_document" "cluster" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "AmazonEKSClusterPolicy" {
  name = "AmazonEKSClusterPolicy"
}

data "aws_iam_policy" "AmazonEKSVPCResourceController" {
  name = "AmazonEKSVPCResourceController"
}

resource "aws_iam_role" "cluster" {
  name               = "${local.name_prefix}eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster.json

  managed_policy_arns = [
    data.aws_iam_policy.AmazonEKSClusterPolicy.arn,
    data.aws_iam_policy.AmazonEKSVPCResourceController.arn,
  ]

  tags = local.default_tags
}

resource "aws_eks_cluster" "this" {
  name     = "${local.name_prefix}cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster.version

  enabled_cluster_log_types = setsubtract(var.cluster.disabled_logs, [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ])

  vpc_config {
    subnet_ids              = var.cluster.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = length(var.cluster.trusted_cidrs) > 0
    public_access_cidrs     = var.cluster.trusted_cidrs
    # security_group_ids      = [aws_security_group.master.id]
    # (Optional) List of security group IDs for the cross-account elastic network interfaces that Amazon EKS creates to use to allow communication between your worker nodes and the Kubernetes control plane.
  }

  dynamic "kubernetes_network_config" {
    for_each = var.cluster.internal_network_cidr != null ? [1] : []

    content {
      service_ipv4_cidr = var.cluster.internal_network_cidr
    }
  }

  dynamic "encryption_config" {
    for_each = var.cluster.disable_secret_encryption ? [] : [1]

    content {
      provider {
        key_arn = aws_kms_key.cluster.arn
      }
      resources = ["secrets"]
    }
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}cluster"
  })
}
