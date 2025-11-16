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
  value       = module.yandex-vpc.network_id
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

output "kubectl_config" {
  value       = "yc managed-kubernetes cluster get-credentials ${yandex_kubernetes_cluster.k8s_cluster.name} --external"
  description = "Command to configure kubectl"
}

output "mysql_endpoint" {
  value       = "mysql.default.svc.cluster.local:3306"
  description = "MySQL service endpoint within cluster"
}

output "phpmyadmin_url" {
  value       = format("http://%s", kubernetes_service.phpmyadmin-service.status[0].load_balancer[0].ingress[0].ip)
  description = "URL для доступа к phpMyAdmin"
}

output "cluster_status" {
  value = {
    id     = yandex_kubernetes_cluster.k8s_cluster.id
    status = yandex_kubernetes_cluster.k8s_cluster.status
    nodes  = {
      zone_a = yandex_kubernetes_node_group.k8s_node_group["ru-central1-a"].scale_policy[0].auto_scale[0].min
      zone_b = yandex_kubernetes_node_group.k8s_node_group["ru-central1-b"].scale_policy[0].auto_scale[0].min
      zone_d = yandex_kubernetes_node_group.k8s_node_group["ru-central1-d"].scale_policy[0].auto_scale[0].min
    }
  }
  description = "Current cluster status"
}
