# Создание сетей, подсетей и групп безопасности

module "yandex-vpc" {
source = "git::https://github.com/DioRoman/ter-yandex-vpc-module.git?ref=a7c4bbb"
  env_name = var.env_name
  subnets = [
    {
      name        = "public"
      cidr        = var.vpc_default_cidr[0]
      zone        = var.vpc_default_zone[0]
      description = "Public subnet"
    },
    {
      name        = "private-ru-central1-a"
      cidr        = var.vpc_default_cidr[1]
      zone        = var.vpc_default_zone[0]
      description = "Private subnet ru-central1-a"
    },
    {
      name        = "private-ru-central1-b"
      cidr        = var.vpc_default_cidr[2]
      zone        = var.vpc_default_zone[1]
      description = "Private subnet ru-central1-b"
    },
  ]
  
  security_groups = [
    {
      name        = var.security_group_name
      description = "Security group for MYSQL"
      ingress_rules = [
        {
          protocol    = "TCP"
          port        = 80
          description = "HTTP access"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          port        = 443
          description = "HTTPS access"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          port        = 22
          description = "SSH access"
          cidr_blocks = ["0.0.0.0/0"]
        },       
        {
          protocol    = "TCP"
          port        = 3306
          description = "Allow incoming MySQL connections"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "ICMP"
          description = "ICMP"
          cidr_blocks = ["0.0.0.0/0"]
        },
      ],
    egress_rules = [
        {
            protocol    = "ANY"
            description = "Allow all outbound traffic"
            cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    },
  ]
}

# Создание кластера MySQL

resource "yandex_mdb_mysql_cluster" "netology_mysql_cluster" {
  name        = var.mysql_cluster_name
  description = var.mysql_cluster_description
  environment = var.mysql_cluster_environment
  network_id  = module.yandex-vpc.network_id
  version     = var.mysql_version

  # Защита от непреднамеренного удаления

  deletion_protection = var.mysql_deletion_protection

  resources {
    resource_preset_id = var.mysql_resource_preset_id
    disk_type_id       = var.mysql_disk_type_id
    disk_size          = var.mysql_disk_size
  }

  # Настройки резервного копирования

  backup_window_start {
    hours   = var.mysql_backup_window_hours
    minutes = var.mysql_backup_window_minutes
  }

  # Окно технического обслуживания (произвольное время)

  maintenance_window {
    type = var.mysql_maintenance_window_type
  }

  # Размещение хостов MySQL в разных подсетях и зонах доступности
  # для обеспечения отказоустойчивости

  host {
    zone             = var.vpc_default_zone[0]
    subnet_id        = module.yandex-vpc.subnet_ids[1]
    assign_public_ip = false
  }

  host {
    zone             = var.vpc_default_zone[1]
    subnet_id        = module.yandex-vpc.subnet_ids[2]
    assign_public_ip = false
  }

  # Подключение группы безопасности

  security_group_ids = [module.yandex-vpc.security_group_ids[var.security_group_name]]

  mysql_config = {
    sql_mode                      = var.mysql_sql_mode
    max_connections               = var.mysql_max_connections
    default_authentication_plugin = var.mysql_auth_plugin
  }
}

# Создание базы данных netology_db
resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.netology_mysql_cluster.id
  name       = "netology_db"
}

# Генерация пароля, если не задан var.db_password
resource "random_password" "mysql" {
  length  = 20
  special = true
  upper   = true
  lower   = true
  numeric = true

  # чтобы контролировать ротацию пароля вручную
  keepers = {
    version = var.mysql_password_version
  }
}

# Если var.db_password не пустой — используем его, иначе сгенерированный
locals {
  mysql_password = var.db_password != "" ? var.db_password : random_password.mysql.result
}

# Сам секрет Lockbox
resource "yandex_lockbox_secret" "mysql_password" {
  name                  = var.mysql_secret_name
  description           = var.mysql_secret_description
  folder_id             = var.folder_id
  kms_key_id            = var.kms_key_id # опционально
  deletion_protection   = var.mysql_secret_deletion_protection
  labels                = var.mysql_secret_labels
}

# Версия секрета
resource "yandex_lockbox_secret_version_hashed" "my_version" {
  secret_id    = yandex_lockbox_secret.mysql_password.id

  key_1        = "MySQL"
  text_value_1 = random_password.mysql.result
}

resource "yandex_mdb_mysql_user" "netology_user" {
  cluster_id = yandex_mdb_mysql_cluster.netology_mysql_cluster.id
  name       = var.mysql_user_name
  password   = local.mysql_password

  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
    roles         = ["ALL"]
  }

  authentication_plugin = var.mysql_auth_plugin
}