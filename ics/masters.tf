resource "openstack_compute_instance_v2" "master_nodes" {
  for_each = toset(keys(var.masters))

  name        = each.value
  flavor_name = local.sizes[var.masters[each.value].size]
  key_pair    = var.ssh_keys[0]
  image_id    = data.openstack_images_image_v2.ubuntu.id

  security_groups = [
    openstack_networking_secgroup_v2.cluster_internal.name,
    openstack_networking_secgroup_v2.allow_ssh.name,
    openstack_networking_secgroup_v2.allow_api.name,
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

  network {
    uuid = openstack_networking_network_v2.kcp.id
  }

  depends_on = [
    openstack_networking_router_interface_v2.kcp,
  ]

}

resource "openstack_networking_secgroup_v2" "allow_ssh" {
  name        = "allow-ssh"
  description = "Allow SSH access from jumpproxy"
}

resource "openstack_networking_secgroup_rule_v2" "allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_group_id   = openstack_networking_secgroup_v2.external_ssh.id
  security_group_id = openstack_networking_secgroup_v2.allow_ssh.id
}

resource "openstack_networking_secgroup_v2" "allow_api" {
  name        = "allow-api"
  description = "Allow K8s API access from jumpproxy"
}

resource "openstack_networking_secgroup_rule_v2" "allow_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_group_id   = openstack_networking_secgroup_v2.external_api.id
  security_group_id = openstack_networking_secgroup_v2.allow_api.id
}

resource "openstack_networking_secgroup_v2" "cluster_internal" {
  name        = "cluster-internal"
  description = "Allow unrestricted access between nodes"
}

resource "openstack_networking_secgroup_rule_v2" "internal_tcp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_group_id   = openstack_networking_secgroup_v2.cluster_internal.id
  security_group_id = openstack_networking_secgroup_v2.cluster_internal.id
}

resource "openstack_networking_secgroup_rule_v2" "internal_udp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  remote_group_id   = openstack_networking_secgroup_v2.cluster_internal.id
  security_group_id = openstack_networking_secgroup_v2.cluster_internal.id
}

resource "openstack_networking_secgroup_rule_v2" "internal_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_group_id   = openstack_networking_secgroup_v2.cluster_internal.id
  security_group_id = openstack_networking_secgroup_v2.cluster_internal.id
}
