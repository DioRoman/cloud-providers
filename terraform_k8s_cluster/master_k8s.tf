resource "yandex_kubernetes_cluster" "k8s_cluster" {
  name                  = "ha-k8s-cluster"
  description           = "Highly available Kubernetes cluster"
  network_id            = module.yandex-vpc.network_id
  cluster_ipv4_range    = var.cluster_ipv4_range
  service_ipv4_range    = var.service_ipv4_range
  release_channel       = "REGULAR"
  master {
    version = var.k8s_version
    master_location {
      zone      = var.subnets[0].zone
      subnet_id = module.yandex-vpc.subnet_ids[0]
    }
    security_group_ids = [module.yandex-vpc.security_group_ids["k8s-security-group"]]
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
