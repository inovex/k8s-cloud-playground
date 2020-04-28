module "lb_masters" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 5.0"

  name = "${var.project_name}-masters"

  load_balancer_type = "network"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  target_groups = [
    {
      name_prefix      = "k8s-m-"
      backend_protocol = "TCP"
      backend_port     = 6443
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 6443
      protocol           = "TCP"
      target_group_index = 0
    }
  ]

  tags = {
    Owner = var.owner_tag
  }
}

resource "aws_lb_target_group_attachment" "masters" {
  for_each = toset(keys(var.masters))

  target_group_arn = module.lb_masters.target_group_arns[0]
  target_id        = aws_instance.master_nodes[each.value].id
}
