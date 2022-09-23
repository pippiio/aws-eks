resource "aws_eks_addon" "this" {
  for_each = toset(local.addons)

  depends_on = [
    aws_eks_node_group.this
  ]

  cluster_name      = aws_eks_cluster.this.name
  addon_name        = each.value
  resolve_conflicts = "OVERWRITE"
}
