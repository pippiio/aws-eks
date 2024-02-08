variable "cluster" {
  type = object({
    version                   = optional(string, "1.29")
    subnet_ids                = set(string)
    public_api                = optional(bool, false)
    trusted_cidrs             = optional(set(string), [])
    trusted_security_groups   = optional(set(string), [])
    internal_network_cidr     = optional(string, "192.168.0.0/16")
    disable_secret_encryption = optional(bool, false)
    disabled_logs             = optional(set(string), [])
    log_retention_in_days     = optional(number, 7)
    administrator_role_arn    = optional(string)
  })
}

variable "addons" {
  type = object({
    coredns                         = optional(bool, true)
    kube-proxy                      = optional(bool, true)
    vpc-cni                         = optional(bool, true)  # AmazonEKSVPCCNIRole
    aws-ebs-csi-driver              = optional(bool, true)  # AmazonEBSCSIDriverPolicy
    aws-efs-csi-driver              = optional(bool, false) # AmazonEFSCSIDriverPolicy
    snapshot-controller             = optional(bool, false)
    amazon-cloudwatch-observability = optional(bool, false) #  AWSXrayWriteOnlyAccess and CloudWatchAgentServerPolicy
    aws-mountpoint-s3-csi-driver    = optional(bool, false) # AmazonEKS_S3_CSI_DriverRole
  })
  default = {}
}

variable "node_group" {
  type = map(object({
    version        = optional(string)
    subnet_ids     = optional(set(string))
    instance_types = optional(set(string), ["t3.small"])
    volumne_size   = optional(number)
    spot_instance  = optional(bool, false)
    min_size       = optional(number, 1)
    max_size       = optional(number, 5)
    desired_size   = optional(number)
    labels         = optional(map(string), {})
    ec2_ssh_key    = optional(string)
  }))
  default = {
    default_wng = {}
  }
}
