provider "google" {
  credentials = file("${path.module}/credentials.json")
  project     = var.project
  region      = var.region
  zone        = "${var.region}-b"
}

resource "google_compute_network" "k8s_network" {
  name                    = "k8s-network"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "ssh_access" {
  name    = "ssh-access"
  network = google_compute_network.k8s_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
    #source_ranges = var.admin_cidrs
  }

}
