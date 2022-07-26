resource "openstack_networking_network_v2" "kcp" {
  name           = "kcp"
  admin_state_up = "true"
  dns_domain     = "${var.project_name}.fra.ics.inovex.io."
}

resource "openstack_networking_subnet_v2" "kcp" {
  name       = "kcp"
  network_id = openstack_networking_network_v2.kcp.id
  cidr       = var.internal_cidr
  ip_version = 4
}

resource "openstack_networking_router_v2" "kcp" {
  name                = "kcp"
  admin_state_up      = "true"
  external_network_id = data.openstack_networking_network_v2.public.id
}

resource "openstack_networking_router_interface_v2" "kcp" {
  router_id = openstack_networking_router_v2.kcp.id
  subnet_id = openstack_networking_subnet_v2.kcp.id
}
