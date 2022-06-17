# pippiio aws-eks
Terraform module for deploying AWS EKS (Kubernetes) resources

## Usage
```hcl
module "eks" {
  source = "github.com/pippiio/aws-eks.git"

  name_prefix = "my-"

  config = {
    vpc_id               = "vpc-1234556qwer"
    private_subnet_ids   = ["subnet-qwer1", "subnet-qwer2", "subnet-qwer3"]
    worker_node_count    = 2
    worker_instance_type = "t3.small"
    worker_volume_size   = 20
    api_allowed_ips      = [0.0.0.0/0]
  }
}
```

## Requirements
|Name     |Version |
|---------|--------|
|terraform|>= 1.2.0|
|aws      |~> 4.0  |


## Variables
### config:
|Name                |Type        |Default     |Required|Description|
|--------------------|------------|------------|--------|-----------|
|vpc_id              |string      |nil         |yes     |Id of VPC to deploy to|
|private_subnet_ids  |list(string)|nil         |yes     |Ids of private subnets to deploy to|
|public_subnet_ids   |list(string)|nil         |yes     |Ids of public subnets to deploy to|
|cluster_version     |string      |1.22        |no      |Version of EKS cluster|
|worker_node_count   |number      |nil         |yes     |Count of worker nodes to deploy|
|worker_instance_type|string      |nil         |yes     |Instance type of worker nodes|
|worker_volume_size  |number      |nil         |yes     |Volume size of worker nodes|
|api_allowed_ips     |list(string)|["0.0.0.0/0]|no      |Allowed IP's to communicate with cluster API|
|addons              |list(string)|nil         |no      |AWS EKS Addons to install on cluster|

### name_prefix:
|Type        |Default|Required|Description|
|------------|-------|--------|-----------|
|string      |pippi- |no      |A prefix that will be used on all named resources|

### default_tags:
|Type        |Default|Required|Description|
|------------|-------|--------|-----------|
|map(string) |nil    |no      |A map of default tags, that will be applied to all resources applicable|
