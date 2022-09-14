data "aws_ssm_parameters_by_path" "k8s_secrets" {
  path      = "/kubernetes"
  recursive = true
}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

locals {
  config = defaults(var.config, {
    cluster_version     = "1.22"
    api_allowed_ips     = "0.0.0.0/0"
    efs_enabled         = false
    ssh_enabled         = false
    ssh_security_groups = ""
  })

  fixed_addons = [
    "vpc-cni",
    "coredns",
    "kube-proxy",
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

  k8s_secrets = {
    for name in data.aws_ssm_parameters_by_path.k8s_secrets.names : name => {
      secret_name      = split("/", name)[3]
      secret_namespace = split("/", name)[2]
      secret_value     = data.aws_ssm_parameters_by_path.k8s_secrets.values[index(data.aws_ssm_parameters_by_path.k8s_secrets.names, name)]
    }
  }
}
