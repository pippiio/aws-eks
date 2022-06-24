locals {
  config = defaults(var.config, {
    cluster_version = "1.22"
    api_allowed_ips = "0.0.0.0/0"
    efs_enabled     = false
  })

  fixed_addons = [
    "vpc-cni",
    "coredns",
    "kube-proxy"
  ]
  addons = concat(local.config.addons, local.fixed_addons)

  nlb_ports = {
    http = {
      listen = 80,
      target = 31080,
    },
    https = {
      listen = 443,
      target = 31443,
    },
  }
}