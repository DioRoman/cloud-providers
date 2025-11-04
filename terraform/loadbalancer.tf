resource "yandex_vpc_address" "nlb_external_ip" {
  name      = "nlb-external-ip"
  folder_id = var.folder_id

  external_ipv4_address {
    zone_id = var.vpc_default_zone[0]
  }
}

resource "yandex_lb_network_load_balancer" "web_nlb" {
  name      = "web-nlb"
  folder_id = var.folder_id

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      address = yandex_vpc_address.nlb_external_ip.external_ipv4_address[0].address
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lamp_target_group.id

    healthcheck {
      name = "http-health-check"
      http_options {
        port = 80
        path = "/"
      }
      interval          = 10
      timeout           = 5
      unhealthy_threshold = 3
      healthy_threshold   = 2
    }
  }
}

locals {
  vm_internal_ips = compact([
    for instance in yandex_compute_instance_group.vm_public_group.instances :
    try(instance.network_interface[0].ip_address, null)
  ])
}

resource "yandex_lb_target_group" "lamp_target_group" {
  name        = "lamp-target-group"
  description = "Target group for LAMP VMs"
  folder_id   = var.folder_id

  dynamic "target" {
    for_each = local.vm_internal_ips
    content {
      subnet_id = module.yandex-vpc.subnet_ids[0]
      address   = target.value
    }
  }
}