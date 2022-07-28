# Outputs from ICS cluster

output "initial_master_ip" {
  value = module.ics_cluster.initial_master_ip
}

output "cp_endpoint_ip" {
  value = module.ics_cluster.cp_endpoint_ip
}

output "ingress_ip" {
  value = module.ics_cluster.ingress_ip
}

output "haproxycfg" {
  value = module.ics_cluster.haproxycfg
}

output "dns_domain" {
  value = module.ics_cluster.dns_domain
}

## Outputs from DO cluster
#
# output "initial_master_ip" {
#   value = module.do_cluster.initial_master_ip
# }
#
# output "cp_endpoint_ip" {
#   value = module.do_cluster.cp_endpoint_ip
# }
#
# output "ingress_ip" {
#   value = module.do_cluster.ingress_ip
# }

## Outputs from aws cluster
#
# output "initial_master_ip" {
#   value = module.aws_cluster.initial_master_ip
# }
#
# output "cp_endpoint_ip" {
#   value = module.aws_cluster.cp_endpoint_ip
# }
#
# output "ingress_ip" {
#   value = module.aws_cluster.ingress_ip
# }
