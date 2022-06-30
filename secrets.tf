resource "kubernetes_secret_v1" "k8s_secrets" {
  for_each = local.k8s_secrets

  metadata {
    name      = each.value.secret_name
    namespace = each.value.secret_namespace
  }

  data = {
    value = each.value.secret_value
  }
}