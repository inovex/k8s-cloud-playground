output "initial_master_ip" {
  value = try(aws_instance.master_nodes[var.initial_master].public_ip, "")
}

output "cp_endpoint_ip" {
  value = module.lb_masters.this_lb_dns_name
}

output "ingress_ip" {
  value = ""
}
