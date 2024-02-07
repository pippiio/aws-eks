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