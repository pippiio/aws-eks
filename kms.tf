data "aws_iam_policy_document" "kms" {
  statement {
    sid       = "Allow IAM policy control of key"
    resources = ["*"]
    actions   = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.id}:root"]
    }
  }

  statement {
    sid       = "Allow ${var.name_prefix}EKS Cluster usage"
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",

      "kms:*", #TODO
    ]

    # principals {
    #   type        = "AWS"
    #   identifiers = [aws_iam_role.cluster.arn]
    # }
    principals { #TODO
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }

  statement {
    sid       = "Allow CloudWatch Logs"
    resources = ["*"]
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]

    principals {
      type        = "Service"
      identifiers = ["logs.${local.region_name}.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.region_name}:${local.account_id}:log-group:/aws/eks/${local.name_prefix}cluster/cluster"]
    }
  }
}

resource "aws_kms_key" "cluster" {
  description         = "KMS CMK used by eks cluster."
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}eks-kms"
  })
}

resource "aws_kms_alias" "cluster" {
  name          = "alias/${var.name_prefix}eks-cluster-kms-cmk"
  target_key_id = aws_kms_key.cluster.key_id
}
