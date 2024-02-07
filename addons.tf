locals {
  coredns_version = {
    "1.29" = "v1.11.1-eksbuild.6"
    "1.28" = "v1.10.1-eksbuild.7"
    "1.27" = "v1.10.1-eksbuild.7"
    "1.26" = "v1.9.3-eksbuild.11"
    "1.25" = "v1.9.3-eksbuild.11"
    "1.24" = "v1.9.3-eksbuild.11"
    "1.23" = "v1.8.7-eksbuild.10"
  }
}

# resource "aws_eks_addon" "coredns" {
#   count = var.addons.coredns.disabled ? 0 : 1

#   cluster_name  = aws_eks_cluster.this.name
#   addon_name    = "coredns"
#   addon_version = coalesce(var.addons.coredns.version, local.coredns_version[var.cluster.version])
#   # resolve_conflicts_on_create = "OVERWRITE"
#   # resolve_conflicts_on_update = "OVERWRITE"

#   tags = local.default_tags
# }


# resource "aws_eks_addon" "this" {
#   for_each = toset(local.addons)

#   depends_on = [
#     aws_eks_node_group.this
#   ]

#   cluster_name      = aws_eks_cluster.this.name
#   addon_name        = each.value
#   resolve_conflicts = "OVERWRITE"

#   lifecycle {
#     ignore_changes = [
#       modified_at
#     ]
#   }
# }

# addon_name – (Required) Name of the EKS add-on. The name must match one of the names returned by describe-addon-versions.
# cluster_name – (Required) Name of the EKS Cluster. Must be between 1-100 characters in length. Must begin with an alphanumeric character, and must only contain alphanumeric characters, dashes and underscores (^[0-9A-Za-z][A-Za-z0-9\-_]+$).