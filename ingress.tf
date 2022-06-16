resource "aws_lb_target_group" "workers" {
  for_each = local.nlb_ports

  name        = "${local.name_prefix}workers-${each.key}"
  vpc_id      = local.config.vpc_id
  target_type = "instance"

  protocol = "TCP"
  port     = each.value.target

  health_check {
    protocol = "HTTP"
    port     = 10254
    path     = "/healthz"

    healthy_threshold   = 3
    unhealthy_threshold = 3

    interval = 10
  }
}