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
