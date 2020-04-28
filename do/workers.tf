resource "digitalocean_droplet" "worker_nodes" {
  for_each           = toset(keys(var.workers))
  image              = "ubuntu-18-04-x64"
  name               = each.value
  region             = var.region
  size               = local.sizes[var.workers[each.value].size]
  private_networking = false
  ssh_keys           = [for sk in data.digitalocean_ssh_key.keys : sk.id]

  user_data = templatefile(
    "${path.root}/scripts/install_node.sh",
    merge(
      local.template_params,
      {
        host_name   = each.value
        kubeadmconf = templatefile(var.joinconf_file, local.template_params)
      }
    )
  )


  lifecycle {
    ignore_changes = [
      # Do not recreate the node unless tainted.
      image, user_data
    ]
  }

  tags = ["worker"]
}

resource "digitalocean_project_resources" "worker_nodes" {
  project   = digitalocean_project.k8s.id
  resources = [for node in digitalocean_droplet.worker_nodes : node.urn]
}

resource "digitalocean_firewall" "workers" {
  name = "k8s-workers"

  droplet_ids = [for node in digitalocean_droplet.worker_nodes : node.id]

  # Management access
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.admin_cidrs
  }

  # ingress access from the loadbalancer
  inbound_rule {
    protocol                  = "tcp"
    port_range                = "30080"
    source_load_balancer_uids = [digitalocean_loadbalancer.ingress.id]
  }

  inbound_rule {
    protocol                  = "tcp"
    port_range                = "30443"
    source_load_balancer_uids = [digitalocean_loadbalancer.ingress.id]
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
