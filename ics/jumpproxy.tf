locals {
  haproxycfg = templatefile(
    var.haproxycfg_file,
    {
      api_server = var.initial_master
      api_ip     = openstack_compute_instance_v2.master_nodes[var.initial_master].access_ip_v4
      workers = {
        for name, worker in openstack_compute_instance_v2.worker_nodes :
        name => worker.access_ip_v4
      }
    }
  )
}

resource "openstack_compute_instance_v2" "jumpproxy" {
  name        = "jumpproxy"
  flavor_name = local.sizes["M"]
  key_pair    = var.ssh_keys[0]
  image_id    = data.openstack_images_image_v2.ubuntu.id

  security_groups = [
    openstack_networking_secgroup_v2.external_ssh.name,
    openstack_networking_secgroup_v2.external_api.name,
    openstack_networking_secgroup_v2.external_ingress.name,
  ]

  user_data = templatefile(
    "${path.root}/scripts/install_jumpproxy.sh",
    {
      haproxycfg = local.haproxycfg
    }
  )

  network {
    uuid = openstack_networking_network_v2.kcp.id
  }

  lifecycle {
    ignore_changes = [
      user_data
    ]
  }

  depends_on = [
    openstack_networking_router_interface_v2.kcp,
  ]

}

resource "openstack_networking_floatingip_v2" "jumpproxy" {
  pool = "public"
}

resource "openstack_compute_floatingip_associate_v2" "jumpproxy" {
  floating_ip = openstack_networking_floatingip_v2.jumpproxy.address
  instance_id = openstack_compute_instance_v2.jumpproxy.id
}

resource "openstack_networking_secgroup_v2" "external_ssh" {
  name        = "external-ssh"
  description = "Allow SSH access"
}

resource "openstack_networking_secgroup_rule_v2" "external_ssh" {
  count = length(var.admin_cidrs)

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.admin_cidrs[count.index]
  security_group_id = openstack_networking_secgroup_v2.external_ssh.id
}

resource "openstack_networking_secgroup_v2" "external_api" {
  name        = "external-api"
  description = "Allow K8s API access"
}

resource "openstack_networking_secgroup_rule_v2" "external_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.external_api.id
}

resource "openstack_networking_secgroup_v2" "external_ingress" {
  name        = "external-ingress"
  description = "Allow external ingress"
}

resource "openstack_networking_secgroup_rule_v2" "external_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.external_ingress.id
}

resource "openstack_networking_secgroup_rule_v2" "external_tls" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.external_ingress.id
}
