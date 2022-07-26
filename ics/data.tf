data "openstack_images_image_v2" "ubuntu" {
  most_recent = true
  visibility  = "public"

  # ICS custom properties.
  properties = {
    os_distro  = "ubuntu"
    os_version = "20.04"
  }
}

data "openstack_networking_network_v2" "public" {
  name = "public"
}

data "openstack_dns_zone_v2" "dns_zone" {
  name = "${local.dns_domain}."
}

locals {
  sizes = {
    "S" = "t2.micro"
    "M" = "c4.large"
  }
  dns_domain = "${var.project_name}.fra.ics.inovex.io"
  template_params = merge(
    var.template_params,
    {
      cp_endpoint = openstack_networking_floatingip_v2.jumpproxy.address
    }
  )
}
