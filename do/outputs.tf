output "initial_master_ip" {
  value = try(digitalocean_droplet.master_nodes[var.initial_master].ipv4_address, "")
}

output "cp_endpoint_ip" {
  value = digitalocean_loadbalancer.masters.ip
}

output "ingress_ip" {
  value = digitalocean_loadbalancer.ingress.ip
}
