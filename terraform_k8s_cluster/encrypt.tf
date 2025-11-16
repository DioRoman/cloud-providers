resource "yandex_kms_symmetric_key" "k8s_encryption_key" {
  name                = var.kms_key_name
  description         = "KMS key for Kubernetes secrets encryption"
  default_algorithm   = "AES_128"
  rotation_period     = var.kms_key_rotation_period
  labels              = var.kms_key_labels
}
