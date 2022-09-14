### Cluster ###
resource "aws_eks_cluster" "this" {
  name     = "${local.name_prefix}cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = local.config.cluster_version

  vpc_config {
    subnet_ids              = local.config.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = local.config.api_allowed_ips
    security_group_ids      = [aws_security_group.master.id]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.cluster.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}cluster"
  })

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController
  ]
}

resource "aws_eks_node_group" "this" {
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]

  cluster_name = aws_eks_cluster.this.name
  # node_group_name = "${local.name_prefix}nodes"
  node_group_name = "${local.name_prefix}nodes-${random_pet.node_group.id}"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = local.config.private_subnet_ids

  scaling_config {
    desired_size = local.config.worker_node_count
    max_size     = local.config.worker_node_count
    min_size     = 1
  }

  ami_type       = "AL2_x86_64" # AL2_x86_64|AL2_x86_64_GPU|AL2_ARM_64
  instance_types = [local.config.worker_instance_type]
  # capacity_type = ON_DEMAND|SPOT
  disk_size = local.config.worker_volume_size
  # force_update_version - (Optional) Force version update if existing pods are unable to be drained due to a pod disruption budget issue.

  # labels - (Optional) Key-value map of Kubernetes labels. 
  # launch_template - (Optional) Configuration block with Launch Template settings. Detailed below.
  dynamic "remote_access" {
    for_each = local.config.ssh_enabled ? {1:1} : {}

    content {
      ec2_ssh_key               = one(aws_key_pair.worker).key_name
      source_security_group_ids = local.config.ssh_security_groups
    }
  }

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}nodegroup"
  })
  version = aws_eks_cluster.this.version

  lifecycle {
    ignore_changes        = [scaling_config[0].desired_size]
    create_before_destroy = true
  }
}

resource "random_pet" "node_group" {
}

data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "tls_private_key" "worker" {
  count = local.config.ssh_enabled ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "worker" {
  count = local.config.ssh_enabled ? 1 : 0

  key_name   = "WorkerNodeSSH"
  public_key = one(tls_private_key.worker).public_key_openssh
}
