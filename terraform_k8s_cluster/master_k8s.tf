resource "yandex_kubernetes_cluster" "k8s_cluster" {
  name            = "ha-k8s-cluster"
  description     = "Highly available Kubernetes cluster"
  network_id      = yandex_vpc_network.k8s_network.id
  cluster_ipv4_range = "10.1.0.0/16"
  service_ipv4_range = "10.2.0.0/16"
  release_channel    = "REGULAR"

  master {
    version = "1.32"  # Используйте проверенную версию

    # Начните с одной зоны
    master_location {
      zone      = yandex_vpc_subnet.k8s_subnet_a.zone
      subnet_id = yandex_vpc_subnet.k8s_subnet_a.id
    }

    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]

    # Безопасные настройки
    public_ip = true

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        day        = "sunday"
        start_time = "22:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = yandex_iam_service_account.k8s_sa.id
  node_service_account_id = yandex_iam_service_account.k8s_sa.id

  depends_on = [
    yandex_resourcemanager_folder_iam_member.k8s_clusters_agent,
    yandex_resourcemanager_folder_iam_member.vpc_public_admin,
    yandex_resourcemanager_folder_iam_member.images_puller,
    yandex_resourcemanager_folder_iam_member.kms_encrypter_decrypter
  ]

  timeouts {
    create = "60m"
    update = "60m"
    delete = "15m"
  }
}