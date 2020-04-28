resource "google_compute_instance" "master_nodes" {
  for_each = toset(keys(var.masters))

  name           = each.value
  description    = "Master Node ${each.value}"
  machine_type   = local.sizes[var.masters[each.value].size]
  can_ip_forward = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_image.self_link
    }
  }

  network_interface {
    network = google_compute_network.k8s_network.self_link
    access_config {
    }
  }

  metadata_startup_script = templatefile(
    "${path.root}/scripts/install_node.sh",
    {
      cp_endpoint    = ""
      host_name      = each.value
      initial_master = var.initial_master
      is_master      = true
      k8s_version    = var.k8s_version
      kubeadmconf = templatefile(
        "${path.root}/scripts/kubeadmconf-${var.kubeadmconf}.yaml",
        {
          cp_endpoint = ""
          k8s_version = var.k8s_version
      })
      join_token = var.join_token
      cert_hash  = var.cert_hash
      cert_key   = var.cert_key
    }
  )

  lifecycle {
    ignore_changes = [
      # Do not recreate the node unless tainted.
      boot_disk, metadata_startup_script
    ]
  }
}

