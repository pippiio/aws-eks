resource "aws_efs_file_system" "this" {
  count = local.config.efs_enabled ? 1 : 0

  creation_token = "${local.name_prefix}${aws_eks_cluster.this.name}-efs"

  tags = merge(local.default_tags, {
    "Name" = "${local.name_prefix}${aws_eks_cluster.this.name}-efs"
  })
}

resource "aws_efs_mount_target" "this" {
  for_each = local.config.efs_enabled ? { for id in local.config.private_subnet_ids : id => id } : {}

  file_system_id = aws_efs_file_system.this[0].id
  subnet_id      = each.key
}