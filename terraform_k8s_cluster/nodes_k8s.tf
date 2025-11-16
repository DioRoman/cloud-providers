resource "yandex_kubernetes_node_group" "k8s_node_group" {
  for_each = { for idx, subnet in var.subnets : subnet.zone => idx }

  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  name       = "k8s-node-group-${each.key}"
  version    = var.k8s_version

  instance_template {
    platform_id = "standard-v3"
    network_interface {
      subnet_ids         = [module.yandex-vpc.subnet_ids[each.value]]
      nat                = true
      security_group_ids = [module.yandex-vpc.security_group_ids["k8s-security-group"]]
    }
    resources {
      cores         = 4
      memory        = 2
      core_fraction = 50
    }
    boot_disk {
      type = "network-ssd"
      size = 30
    }
    scheduling_policy {
      preemptible = true
    }
  }
  scale_policy {
    auto_scale {
      min     = 1
      max     = 3
      initial = 1
    }
  }
  allocation_policy {
    location {
      zone = each.key
    }
  }
  maintenance_policy {
    auto_repair  = true
    auto_upgrade = true
    maintenance_window {
      day        = "sunday"
      start_time = "23:00"
      duration   = "2h"
    }
  }
  depends_on = [yandex_kubernetes_cluster.k8s_cluster]
}
