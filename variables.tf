variable "config" {
  type = object({
    vpc_id                 = string
    private_subnet_ids     = set(string)
    public_subnet_ids      = set(string)
    cluster_version        = optional(string, "1.29")
    worker_node_count      = number
    worker_instance_type   = string
    worker_volume_size     = number
    api_allowed_ips        = optional(set(string), ["0.0.0.0/0"])
    addons                 = optional(set(string))
    efs_enabled            = optional(bool, false)
    administrator_role_arn = optional(string)
    ssh_enabled            = optional(bool, false)
    ssh_security_groups    = optional(set(string), [])
  })
}