resource "yandex_kms_symmetric_key" "k8s_encryption_key" {
  name                = "k8s-secrets-encryption-key"
  description         = "KMS key for Kubernetes secrets encryption"
  default_algorithm   = "AES_128"
  rotation_period     = "8760h"  # 1 год в часах
  
  labels = {
    purpose = "kubernetes"
    type    = "cluster-encryption"
  }
}