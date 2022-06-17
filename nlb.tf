resource "aws_lb" "nlb" {
  name               = "${local.name_prefix}nlb"
  load_balancer_type = "network"
  ip_address_type    = "ipv4"
  internal           = false

  subnets = local.config.public_subnet_ids

  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "ingress_http" {
  for_each = local.nlb_ports

  load_balancer_arn = aws_lb.nlb.arn
  protocol          = "TCP"
  port              = each.value.listen

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.workers[each.key].arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  for_each = aws_lb_target_group.workers

  autoscaling_group_name = aws_eks_node_group.this.resources[0].autoscaling_groups[0].name
  lb_target_group_arn    = each.value.arn
}
