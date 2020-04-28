resource "digitalocean_droplet" "master_nodes" {
  for_each           = toset(keys(var.masters))
  image              = "ubuntu-18-04-x64"
  name               = each.value
  region             = var.region
  size               = local.sizes[var.masters[each.value].size]
  private_networking = false
  ssh_keys           = [for sk in data.digitalocean_ssh_key.keys : sk.id]

  user_data = templatefile(
    "${path.root}/scripts/install_node.sh",
    merge(
      local.template_params,
      {
        host_name  = each.value
        is_initial = each.value == var.initial_master
        kubeadmconf = templatefile(
          each.value == var.initial_master ? var.kubeadmconf_file : var.joinconf_file,
          merge(local.template_params, { is_master = true })
        )
      }
    )
  )

  lifecycle {
    ignore_changes = [
      # Do not recreate the node unless tainted.
      image, user_data
    ]
  }

  tags = ["master"]
}

resource "digitalocean_project_resources" "master_nodes" {
  project   = digitalocean_project.k8s.id
  resources = [for node in digitalocean_droplet.master_nodes : node.urn]
}

resource "digitalocean_firewall" "masters" {
  name = "k8s-masters"

  droplet_ids = [for node in digitalocean_droplet.master_nodes : node.id]

  # Management access
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.admin_cidrs
  }

  # API access from the loadbalancer
  inbound_rule {
    protocol                  = "tcp"
    port_range                = "6443"
    source_load_balancer_uids = [digitalocean_loadbalancer.masters.id]
  }

  # Unrestricted access from cluster nodes
  inbound_rule {
    protocol    = "tcp"
    port_range  = "1-65535"
    source_tags = ["master", "worker"]
  }

  inbound_rule {
    protocol    = "udp"
    port_range  = "1-65535"
    source_tags = ["master", "worker"]
  }

  inbound_rule {
    protocol    = "icmp"
    source_tags = ["master", "worker"]
  }

  # Unrestricted outbound access
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
