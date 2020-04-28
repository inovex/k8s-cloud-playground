resource "aws_instance" "worker_nodes" {
  for_each = toset(keys(var.workers))

  ami                  = data.aws_ami.ubuntu.id
  instance_type        = local.sizes[var.workers[each.value].size]
  key_name             = var.ssh_keys[0]
  iam_instance_profile = aws_iam_instance_profile.worker_nodes.name

  # Spread nodes across AZs consistently.
  subnet_id = module.vpc.public_subnets[index(local.ordered_workers, each.value) % var.az_count]


  vpc_security_group_ids = [
    aws_security_group.all_nodes.id
  ]

  user_data = templatefile(
    "${path.root}/scripts/install_node.sh",
    merge(
      local.template_params,
      {
        host_name   = each.value
        kubeadmconf = templatefile(var.joinconf_file, local.template_params)
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
