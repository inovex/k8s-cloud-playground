output "initial_master_ip" {
  value = try(
    google_compute_instance.master_nodes[var.initial_master].network_interface[0].access_config[0].nat_ip,
    ""
  )
}

output "cp_endpoint_ip" {
  value = ""
}

output "ingress_ip" {
  value = ""
}
