resource "yandex_compute_instance_group" "vm_public_group" {
  name               = "vm-public-group"
  folder_id          = var.folder_id
  service_account_id = var.service_account_id

  scale_policy {
    fixed_scale {
      size = var.vm_public[0].instance_count
    }
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
  }

  allocation_policy {
    zones = [var.vpc_default_zone[0]]
  }

  instance_template {
    platform_id = var.vm_public[0].platform_id

    resources {
      cores  = var.vm_public[0].cores
      memory = var.vm_public[0].memory
    }

    boot_disk {
      initialize_params {
        image_id = var.vm_lamp_image
        size     = var.vm_public[0].disk_size
      }
    }

    network_interface {
      subnet_ids         = [module.yandex-vpc.subnet_ids[0]]
      nat                = var.vm_public[0].public_ip
      security_group_ids = [module.yandex-vpc.security_group_ids["web"]]
    }

    scheduling_policy {
      preemptible = true
    }

    metadata = {
      user-data          = data.template_file.vm-lamp.rendered
      serial-port-enable = local.serial-port-enable
    }

    labels = {
      env  = var.vm_public[0].env_name
      role = var.vm_public[0].role
    }
  }
}
