data "digitalocean_ssh_key" "keys" {
  for_each = toset(var.ssh_keys)
  name     = each.value
}

locals {
  sizes = {
    "S" = "s-1vcpu-1gb"
    "M" = "s-2vcpu-4gb"
  }

  template_params = merge(
    var.template_params,
    {
      cp_endpoint = digitalocean_loadbalancer.masters.ip
    }
  )
}