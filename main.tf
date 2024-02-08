locals {
  vpc_id = one(distinct([for _ in data.aws_subnet.cluster : _.vpc_id]))
}

data "aws_subnet" "cluster" {
  for_each = var.cluster.subnet_ids

  id = each.value
}
