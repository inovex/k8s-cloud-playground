resource "digitalocean_loadbalancer" "masters" {
  name   = "k8s-control-plane"
  region = var.region

  forwarding_rule {
    entry_port     = 6443
    entry_protocol = "https"

    target_port     = 6443
    target_protocol = "https"

    tls_passthrough = true
  }

  healthcheck {
    port     = 6443
    protocol = "tcp"
  }

  droplet_tag = "master"
}

resource "digitalocean_loadbalancer" "ingress" {
  name   = "k8s-ingress"
  region = var.region

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 30080
    target_protocol = "http"
  }

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"

    target_port     = 30443
    target_protocol = "https"

    tls_passthrough = true
  }

  healthcheck {
    port     = 30080
    protocol = "tcp"
  }

  droplet_tag = "worker"
}

resource "digitalocean_project_resources" "lb" {
  project = digitalocean_project.k8s.id
  resources = [
    digitalocean_loadbalancer.masters.urn,
    digitalocean_loadbalancer.ingress.urn,
  ]
}
