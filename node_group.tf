data "aws_iam_policy" "AmazonEKSWorkerNodePolicy" {
  name = "AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "AmazonEC2ContainerRegistryReadOnly" {
  name = "AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy_document" "node_group" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_security_group" "node_group" {
  name        = "${local.name_prefix}eks-node-group"
  description = "SG for the ${local.name_prefix}EKS node_group"
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, {
    "Name" = "${var.name_prefix}eks-node-group"
  })
}

# resource "aws_security_group_rule" "node_group" {
#   type              = "ingress"
#   description       = "Allow EKS cluster API communication"
#   security_group_id = aws_security_group.node_group.id
#   self              = true
#   protocol          = -1
#   from_port         = 0
#   to_port           = 0
# }

resource "aws_iam_role" "node_group" {
  name               = "${local.name_prefix}eks-node-group"
  assume_role_policy = data.aws_iam_policy_document.node_group.json
  managed_policy_arns = [
    data.aws_iam_policy.AmazonEKSWorkerNodePolicy.arn,
    data.aws_iam_policy.AmazonEC2ContainerRegistryReadOnly.arn,
  ]
}

resource "aws_eks_node_group" "this" {
  for_each = var.node_group

  cluster_name         = aws_eks_cluster.this.name
  version              = coalesce(each.value.version, aws_eks_cluster.this.version)
  node_group_name      = "${local.name_prefix}${each.key}_${random_pet.node_group.id}"
  node_role_arn        = aws_iam_role.node_group.arn
  subnet_ids           = coalesce(each.value.subnet_ids, var.cluster.subnet_ids)
  instance_types       = each.value.instance_types
  disk_size            = each.value.volumne_size
  capacity_type        = each.value.spot_instance ? "SPOT" : "ON_DEMAND"
  force_update_version = false # - (Optional) Force version update if existing pods are unable to be drained due to a pod disruption budget issue.
  labels               = each.value.labels
  # ami_type       = "AL2_x86_64" # AL2_x86_64|AL2_x86_64_GPU|AL2_ARM_64

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  dynamic "remote_access" {
    for_each = each.value.ec2_ssh_key != null ? [1] : []

    content {
      ec2_ssh_key               = each.value.ec2_ssh_key
      source_security_group_ids = var.cluster.trusted_security_groups
    }
  }

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}eks-wng-${each.key}"
  })

  lifecycle {
    # create_before_destroy = true
    ignore_changes = [
      scaling_config[0].desired_size,
      update_config,
    ]
  }
}

resource "random_pet" "node_group" {
  # keepers = {}

  length    = 2
  separator = "-"
}
