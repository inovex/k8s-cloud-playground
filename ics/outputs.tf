output "initial_master_ip" {
  value = openstack_networking_floatingip_v2.master.address
}

output "cp_endpoint_ip" {
  value = openstack_networking_floatingip_v2.master.address
}

output "ingress_ip" {
  value = ""
}
