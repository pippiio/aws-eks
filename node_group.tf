data "aws_iam_policy" "AmazonEKSWorkerNodePolicy" {
  name = "AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "AmazonEKS_CNI_Policy" {
  name = "AmazonEKS_CNI_Policy"
}

data "aws_iam_policy" "AmazonEC2ContainerRegistryReadOnly" {
  name = "AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy_document" "worker" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "worker" {
  for_each = var.node_group

  name               = "${local.name_prefix}eks-wng-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.worker.json
  managed_policy_arns = [
    data.aws_iam_policy.AmazonEKSWorkerNodePolicy.arn,
    data.aws_iam_policy.AmazonEKS_CNI_Policy.arn,
    data.aws_iam_policy.AmazonEC2ContainerRegistryReadOnly.arn,
  ]

  # inline_policy {
  #   name   = "worker-policy"
  #   policy = data.aws_iam_policy_document.worker_ecr.json
  # }
}

resource "aws_eks_node_group" "this" {
  for_each = var.node_group

  # # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  # depends_on = [
  #   aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
  #   aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
  #   aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  # ]

  cluster_name         = aws_eks_cluster.this.name
  version              = coalesce(each.value.version, aws_eks_cluster.this.version)
  node_group_name      = "${local.name_prefix}${each.key}_${random_pet.node_group.id}"
  node_role_arn        = aws_iam_role.worker[each.key].arn
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

  # dynamic "remote_access" {
  #   for_each = each.value.ec2_ssh_key != null ? [1] : []

  #   content {
  #     ec2_ssh_key               = each.value.ec2_ssh_key
  #     source_security_group_ids = local.config.ssh_security_groups
  #   }
  # }

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}eks-wng-${each.key}"
  })

  lifecycle {
    ignore_changes        = [scaling_config[0].desired_size]
    create_before_destroy = true
  }
}

resource "random_pet" "node_group" {}
