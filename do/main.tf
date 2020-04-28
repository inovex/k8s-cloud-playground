provider "digitalocean" {
}

resource "digitalocean_project" "k8s" {
  name = var.project_name
}
