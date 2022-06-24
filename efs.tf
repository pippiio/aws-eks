resource "aws_efs_file_system" "this" {
  count = local.config.efs_enabled ? 1 : 0

  creation_token = "${local.name_prefix}${aws_eks_cluster.this.name}-efs"

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}${aws_eks_cluster.this.name}-efs"
  })
}

resource "aws_efs_mount_target" "this" {
  count = local.config.efs_enabled ? length(local.config.private_subnet_ids) : 0

  file_system_id = aws_efs_file_system.this[0].id
  subnet_id      = local.config.private_subnet_ids[count.index]
}