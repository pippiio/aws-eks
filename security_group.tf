resource "aws_security_group" "master" {
  name        = "${local.name_prefix}eks-master"
  description = "SG for the ${local.name_prefix}eks Master"
  vpc_id      = local.config.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}eks-master-sg"
  })
}

resource "aws_security_group_rule" "master-ingress-https-sg" {
  type              = "ingress"
  description       = "Allow cluster API communication"
  security_group_id = aws_security_group.master.id
  cidr_blocks       = local.config.api_allowed_ips
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_security_group_rule" "nlb_ports" {
  for_each = local.nlb_ports

  type              = "ingress"
  from_port         = each.value.target
  to_port           = each.value.target
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

resource "aws_security_group_rule" "healtz_ports" {
  type              = "ingress"
  from_port         = 10254
  to_port           = 10254
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

### EFS Security Group ###
resource "aws_security_group" "efs" {
  count = local.config.efs_enabled ? 1 : 0

  name        = "${local.name_prefix}efs-eks"
  description = "SG for the ${local.name_prefix}efs eks"
  vpc_id      = local.config.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.current.cidr_block_associations[0].cidr_block]
  }

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}efs-eks"
  })
}

data "aws_vpc" "current" {
  id = local.config.vpc_id
}