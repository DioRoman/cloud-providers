variable "cloud_id" {
  type        = string
  default     = "b1g2uh898q9ekgq43tfq"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  default     = "b1g22qi1cc8rq4avqgik"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "kms_key_name" {
  type        = string
  default     = "k8s-secrets-encryption-key"
  description = "Name for KMS symmetric key"
}

variable "kms_key_rotation_period" {
  type        = string
  default     = "8760h"
  description = "Rotation period for KMS key (in hours)"
}

variable "kms_key_labels" {
  type        = map(string)
  default     = {
    purpose = "kubernetes"
    type    = "cluster-encryption"
  }
  description = "Labels for KMS key"
}

variable "subnets" {
  type = list(object({
    name        = string
    cidr        = string
    zone        = string
    description = string
    labels      = map(string)
  }))
  default = [
    {
      name        = "k8s-subnet-zone-a"
      cidr        = "10.5.0.0/16"
      zone        = "ru-central1-a"
      description = "Subnet in ru-central1-a"
      labels      = { zone = "ru-central1-a", tier = "worker" }
    },
    {
      name        = "k8s-subnet-zone-b"
      cidr        = "10.6.0.0/16"
      zone        = "ru-central1-b"
      description = "Subnet in ru-central1-b"
      labels      = { zone = "ru-central1-b", tier = "worker" }
    },
    {
      name        = "k8s-subnet-zone-d"
      cidr        = "10.7.0.0/16"
      zone        = "ru-central1-d"
      description = "Subnet in ru-central1-d"
      labels      = { zone = "ru-central1-d", tier = "worker" }
    },
  ]
  description = "List of subnets for VPC"
}

variable "cluster_ipv4_range" {
  type        = string
  default     = "10.1.0.0/16"
  description = "IPv4 range for Kubernetes cluster"
}

variable "service_ipv4_range" {
  type        = string
  default     = "10.2.0.0/16"
  description = "IPv4 range for Kubernetes services"
}

variable "k8s_version" {
  type        = string
  default     = "1.32"
  description = "Kubernetes version"
}

variable "mysql_image" {
  type        = string
  default     = "mysql:8.0"
  description = "MySQL Docker image"
}

variable "mysql_resources" {
  type = object({
    cpu      = string
    memory   = string
    cpu_req  = string
    mem_req  = string
  })
  default = {
    cpu      = "1000m"
    memory   = "1Gi"
    cpu_req  = "500m"
    mem_req  = "512Mi"
  }
  description = "Resource limits and requests for MySQL pod"
}

variable "mysql_password" {
  type        = string
  sensitive   = true
  description = "MySQL root password"
  default     = "ZAQ!xsw2"
}

variable "phpmyadmin_image" {
  type        = string
  default     = "phpmyadmin/phpmyadmin:latest"
  description = "phpMyAdmin Docker image"
}

variable "vpc_default_zone" {
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
  description = "List of default zones for VPC"
}
