output "initial_master_ip" {
  value = openstack_compute_instance_v2.master_nodes[var.initial_master].access_ip_v4
}

output "cp_endpoint_ip" {
  value = openstack_networking_floatingip_v2.jumpproxy.address
}

output "ingress_ip" {
  value = openstack_networking_floatingip_v2.jumpproxy.address
}
