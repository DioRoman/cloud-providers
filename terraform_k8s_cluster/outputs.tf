output "cluster_id" {
  value       = yandex_kubernetes_cluster.k8s_cluster.id
  description = "Kubernetes cluster ID"
}

output "cluster_name" {
  value       = yandex_kubernetes_cluster.k8s_cluster.name
  description = "Kubernetes cluster name"
}

output "kms_key_id" {
  value       = yandex_kms_symmetric_key.k8s_encryption_key.id
  description = "KMS key ID used for encryption"
}

output "service_account_id" {
  value       = yandex_iam_service_account.k8s_sa.id
  description = "Service account ID"
}

output "network_id" {
  value       = yandex_vpc_network.k8s_network.id
  description = "VPC network ID"
}

output "kubeconfig_command" {
  value       = "yc managed-kubernetes cluster get-credentials ${yandex_kubernetes_cluster.k8s_cluster.name} --external"
  description = "Command to configure kubectl"
}

output "master_endpoint" {
  value       = yandex_kubernetes_cluster.k8s_cluster.master[0].external_v4_endpoint
  description = "Master endpoint"
}

output "master_ca_certificate" {
  value       = yandex_kubernetes_cluster.k8s_cluster.master[0].cluster_ca_certificate
  sensitive   = true
  description = "Master CA certificate"
}