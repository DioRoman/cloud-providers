###cloud provider vars

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

###vpc vars

variable "vpc_default_zone" {
  description = "Available default subnets."
  type        = list(string)
  default     = [
    "ru-central1-a",
    "ru-central1-b",
    "ru-central1-d",
  ]
}

variable "vpc_default_cidr" {
  description = "Available cidr blocks for public subnets."
  type        = list(string)
  default     = [
    "192.168.10.0/24",
    "192.168.20.0/24",
    "192.168.30.0/24",
  ]
}

# Переменные для БД

variable "env_name" {
  description = "Environment name"
  type        = string
  default     = "MYSQL-net"
}

variable "mysql_cluster_environment" {
  description = "Environment for MySQL cluster"
  type        = string
  default     = "PRESTABLE"
}

variable "mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "8.0"
}

variable "mysql_deletion_protection" {
  description = "Prevent accidental MySQL cluster deletion"
  type        = bool
  default     = true
}

variable "mysql_resource_preset_id" {
  description = "Resource preset ID"
  type        = string
  default     = "b1.medium"
}

variable "mysql_disk_type_id" {
  description = "Disk type ID"
  type        = string
  default     = "network-ssd"
}

variable "mysql_disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "mysql_backup_window_hours" {
  description = "Backup window start hour"
  type        = number
  default     = 23
}

variable "mysql_backup_window_minutes" {
  description = "Backup window start minute"
  type        = number
  default     = 59
}

variable "mysql_maintenance_window_type" {
  description = "Maintenance window type"
  type        = string
  default     = "ANYTIME"
}

variable "mysql_sql_mode" {
  description = "MySQL sql_mode"
  type        = string
  default     = "ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
}

variable "mysql_max_connections" {
  description = "Max connections to MySQL"
  type        = number
  default     = 100
}

variable "mysql_auth_plugin" {
  description = "Authentication plugin for MySQL"
  type        = string
  default     = "MYSQL_NATIVE_PASSWORD"
}

variable "mysql_database_name" {
  description = "MySQL database name"
  type        = string
  default     = "netology_db"
}

variable "mysql_user_name" {
  description = "MySQL username"
  type        = string
  default     = "netology_admin"
}

# variable "db_password" {
#   description = "Password for MySQL user"
#   type        = string
#   sensitive   = true
#   default     = "romabest"
# }

variable "mysql_cluster_name" {
  description = "MySQL cluster name"
  type        = string
  default     = "netology-mysql-cluster"
}

variable "mysql_cluster_description" {
  description = "MySQL cluster description"
  type        = string
  default     = "MySQL cluster for Netology homework"
}

variable "security_group_name" {
  description = "Security group name"
  type        = string
  default     = "mysql"
}




# Путь КМС ключа опционален; Lockbox может работать и без явного kms_key_id
variable "kms_key_id" {
  description = "KMS key ID used to encrypt Lockbox secret (optional)"
  type        = string
  default     = null
}

variable "mysql_secret_name" {
  description = "Lockbox secret name for MySQL password"
  type        = string
  default     = "mysql-user-password"
}

variable "mysql_secret_description" {
  description = "Description for Lockbox secret with MySQL password"
  type        = string
  default     = "Managed MySQL user password"
}

variable "mysql_secret_labels" {
  description = "Labels for Lockbox secret"
  type        = map(string)
  default     = {
    component = "mysql"
    purpose   = "credentials"
  }
}

variable "mysql_secret_deletion_protection" {
  description = "Enable deletion protection for the Lockbox secret"
  type        = bool
  default     = true
}

# Управление ротацией генерируемого пароля
variable "mysql_password_version" {
  description = "Change this to rotate generated password (keepers)"
  type        = string
  default     = "v1"
}

# Если хотите задать пароль вручную — оставьте непустым, иначе будет сгенерирован
variable "db_password" {
  description = "Optional manual password for MySQL user (overrides generated)"
  type        = string
  sensitive   = true
  default     = ""
}
