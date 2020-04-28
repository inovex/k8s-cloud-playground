data "google_compute_image" "ubuntu_image" {
  family  = "ubuntu-1804-lts"
  project = "ubuntu-os-cloud"
}

locals {
  sizes = {
    "S" = "n1-standard-1"
  }
}