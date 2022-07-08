variable "config" {
  type = object({
    vpc_id                 = string
    private_subnet_ids     = list(string)
    public_subnet_ids      = list(string)
    cluster_version        = optional(string)
    worker_node_count      = number
    worker_instance_type   = string
    worker_volume_size     = number
    api_allowed_ips        = optional(list(string))
    addons                 = optional(list(string))
    efs_enabled            = optional(bool)
    administrator_role_arn = optional(string)
  })
}
