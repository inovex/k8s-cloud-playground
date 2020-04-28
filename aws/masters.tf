resource "aws_instance" "master_nodes" {
  for_each = toset(keys(var.masters))

  ami                  = data.aws_ami.ubuntu.id
  instance_type        = local.sizes[var.masters[each.value].size]
  key_name             = var.ssh_keys[0]
  iam_instance_profile = aws_iam_instance_profile.master_nodes.name

  # Spread nodes across AZs consistently.
  subnet_id = module.vpc.public_subnets[index(local.ordered_masters, each.value) % var.az_count]

  vpc_security_group_ids = [
    aws_security_group.all_nodes.id,
    aws_security_group.master_nodes.id
  ]

  user_data = templatefile(
    "${path.root}/scripts/install_node.sh",
    merge(
      local.template_params,
      {
        host_name  = each.value
        is_initial = each.value == var.initial_master
        kubeadmconf = templatefile(
          each.value == var.initial_master ? var.kubeadmconf_file : var.joinconf_file,
          merge(local.template_params, { is_master = true })
        )
      }
    )
  )

  lifecycle {
    ignore_changes = [
      # Do not recreate the node unless tainted.
      ami, user_data, subnet_id
    ]
  }
  tags = {
    Name                                        = "${var.project_name}-${each.value}"
    Owner                                       = var.owner_tag
    "kubernetes.io/cluster/${var.project_name}" = "managed"
  }
}

resource "aws_security_group" "master_nodes" {
  name_prefix = "${var.project_name}-"
  description = "Access to master nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "API access from all"
    from_port   = 6443
    to_port     = 6443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.project_name}-masters"
    Owner = var.owner_tag
  }
}
