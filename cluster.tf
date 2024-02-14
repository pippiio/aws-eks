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

  inline_policy {
    name = "kms-key-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ListGrants",
          "kms:DescribeKey",
        ]
        Resource = aws_kms_key.cluster.arn
    }] })
  }

  tags = local.default_tags
}

resource "aws_security_group" "cluster" {
  name        = "${local.name_prefix}eks-cluster"
  description = "SG for the ${local.name_prefix}EKS cluster"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.node_group.id]
  }

  tags = merge(local.default_tags, {
    "Name" = "${var.name_prefix}eks-cluster-sg"
  })
}

resource "aws_security_group_rule" "cluster" {
  type              = "ingress"
  description       = "Allow EKS cluster API communication"
  security_group_id = aws_security_group.cluster.id
  self              = true
  protocol          = -1
  from_port         = 0
  to_port           = 0
}

resource "aws_eks_cluster" "this" {
  name     = "${local.name_prefix}cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster.version

  enabled_cluster_log_types = setsubtract([
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ], var.cluster.disabled_logs)

  vpc_config {
    subnet_ids              = var.cluster.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = length(var.cluster.trusted_cidrs) > 0
    public_access_cidrs     = var.cluster.trusted_cidrs
    security_group_ids      = [aws_security_group.cluster.id]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
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

  depends_on = [
    aws_cloudwatch_log_group.cluster
  ]
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.name_prefix}cluster/cluster"
  retention_in_days = var.cluster.log_retention_in_days
  kms_key_id        = aws_kms_key.cluster.arn
  tags              = local.default_tags
}

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
