resource "openstack_compute_instance_v2" "worker_nodes" {
  for_each = toset(keys(var.workers))

  name        = each.value
  flavor_name = local.sizes[var.workers[each.value].size]
  key_pair    = var.ssh_keys[0]
  image_id    = data.openstack_images_image_v2.ubuntu.id

  security_groups = [
    openstack_networking_secgroup_v2.cluster_internal.name,
    openstack_networking_secgroup_v2.allow_ssh.name,
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

  network {
    uuid = openstack_networking_network_v2.kcp.id
  }

  depends_on = [
    openstack_networking_router_interface_v2.kcp,
  ]

}