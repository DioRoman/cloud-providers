# Service Account для управления кластером
resource "yandex_iam_service_account" "k8s_sa" {
  name        = "k8s-cluster-sa"
  description = "Service account for Kubernetes cluster and node management"
  folder_id   = var.folder_id
}

# Ключ для сервис-аккаунта (опционально для API доступа)
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.k8s_sa.id
  description        = "Static access key for service account"
}

# Роль 1: Управление кластером Kubernetes
resource "yandex_resourcemanager_folder_iam_member" "k8s_clusters_agent" {
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# Роль 2: Управление публичными IP (для LoadBalancer сервисов)
resource "yandex_resourcemanager_folder_iam_member" "vpc_public_admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# Роль 3: Загрузка образов из Container Registry
resource "yandex_resourcemanager_folder_iam_member" "images_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# Роль 4: Работа с KMS для шифрования
resource "yandex_resourcemanager_folder_iam_member" "kms_encrypter_decrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}

# Роль 5: Логирование (опционально)
resource "yandex_resourcemanager_folder_iam_member" "logging_writer" {
  folder_id = var.folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.k8s_sa.id}"
}
