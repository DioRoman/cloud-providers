# Первая группа узлов с автомасштабированием
resource "yandex_kubernetes_node_group" "k8s_node_group_a" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  name       = "k8s-node-group-a"
  version    = "1.32"

  instance_template {
    platform_id = "standard-v3"
    
    network_interface {
      subnet_ids = [yandex_vpc_subnet.k8s_subnet_a.id]
      nat        = false
      security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
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
      min     = 3
      max     = 6
      initial = 3
    }
  }

  allocation_policy {
    location {
      zone      = yandex_vpc_subnet.k8s_subnet_a.zone
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

# Вторая группа узлов в зоне b
resource "yandex_kubernetes_node_group" "k8s_node_group_b" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  name       = "k8s-node-group-b"
  version    = "1.32"

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      subnet_ids = [yandex_vpc_subnet.k8s_subnet_b.id]
      nat        = false
      security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
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
      zone      = yandex_vpc_subnet.k8s_subnet_b.zone
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

# Третья группа узлов в зоне d
resource "yandex_kubernetes_node_group" "k8s_node_group_d" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
  name       = "k8s-node-group-d"
  version    = "1.32"

  instance_template {
    platform_id = "standard-v3"

    network_interface {
      subnet_ids = [yandex_vpc_subnet.k8s_subnet_d.id]
      nat        = false
      security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
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
      zone      = yandex_vpc_subnet.k8s_subnet_d.zone
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