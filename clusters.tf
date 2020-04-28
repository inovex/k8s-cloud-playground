locals {
  masters = var.init_phase ? { (var.initial_master) : var.masters[var.initial_master] } : var.masters
  workers = var.init_phase ? {} : var.workers

  kubeadmconf_file = "${path.root}/scripts/kubeadmconf-${var.kubeadmconf}.yaml"
  joinconf_file    = "${path.root}/scripts/joinconf-${var.kubeadmconf}.yaml"

  template_params = {
    provider     = split("-", var.kubeadmconf)[0]
    k8s_version  = var.k8s_version
    cluster_name = var.project_name
    is_master    = false
    is_initial   = false
    join_token   = var.join_token
    cert_hash    = var.cert_hash
    cert_key     = var.cert_key
  }
}

# module "do_cluster" {
#   source = "./do"
#
#   project_name = var.project_name
#   ssh_keys     = var.ssh_keys
#   region       = "fra1"
#
#   kubeadmconf_file = local.kubeadmconf_file
#   joinconf_file    = local.joinconf_file
#   template_params  = local.template_params
#   init_phase       = var.init_phase
#   initial_master   = var.initial_master
#
#   admin_cidrs = var.admin_cidrs
#   masters     = local.masters
#   workers     = local.workers
#
# }

# module "aws_cluster" {
#   source = "./aws"
#
#   project_name = var.project_name
#   ssh_keys     = var.ssh_keys
#   region       = "eu-central-1"
#   owner_tag    = "myname"
#
#   kubeadmconf_file = local.kubeadmconf_file
#   joinconf_file    = local.joinconf_file
#   template_params  = local.template_params
#   init_phase       = var.init_phase
#   initial_master   = var.initial_master
#
#   admin_cidrs = var.admin_cidrs
#   masters     = local.masters
#   workers     = local.workers
#
# }
