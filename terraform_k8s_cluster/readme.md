# Настройка кластера MySQL в Yandex Cloud с помощью Terraform

## Описание конфигурации

Данная конфигурация Terraform создает высокодоступный кластер MySQL в Yandex Cloud согласно требованиям задания:

- **Окружение**: PRESTABLE
- **Платформа**: Intel Broadwell с производительностью 50% CPU (класс хостов `b1.medium`)
- **Размер диска**: 20 ГБ
- **Отказоустойчивость**: 3 хоста в разных зонах доступности (`ru-central1-a`, `ru-central1-b`, `ru-central1-d`)
- **Репликация**: автоматическая репликация между хостами
- **Резервное копирование**: начало в 23:59
- **Техническое обслуживание**: произвольное время (ANYTIME)
- **Защита от удаления**: включена
- **База данных**: `netology_db`
- **Пользователь**: с логином и паролем

## Файл main.tf

```hcl
# Определение провайдера Yandex Cloud
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.110"
    }
  }
  required_version = ">= 1.5.0"
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}

# Переменные
variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "network_id" {
  description = "ID существующей VPC сети из предыдущих домашних заданий"
  type        = string
}

# Создание дополнительных подсетей private в разных зонах доступности
# для обеспечения отказоустойчивости

resource "yandex_vpc_subnet" "mysql_subnet_a" {
  name           = "mysql-subnet-a"
  description    = "Private subnet for MySQL in zone A"
  zone           = "ru-central1-a"
  network_id     = var.network_id
  v4_cidr_blocks = ["10.10.1.0/24"]
}

resource "yandex_vpc_subnet" "mysql_subnet_b" {
  name           = "mysql-subnet-b"
  description    = "Private subnet for MySQL in zone B"
  zone           = "ru-central1-b"
  network_id     = var.network_id
  v4_cidr_blocks = ["10.10.2.0/24"]
}

resource "yandex_vpc_subnet" "mysql_subnet_d" {
  name           = "mysql-subnet-d"
  description    = "Private subnet for MySQL in zone D"
  zone           = "ru-central1-d"
  network_id     = var.network_id
  v4_cidr_blocks = ["10.10.3.0/24"]
}

# Создание группы безопасности для MySQL кластера
resource "yandex_vpc_security_group" "mysql_security_group" {
  name        = "mysql-security-group"
  description = "Security group for MySQL cluster"
  network_id  = var.network_id

  ingress {
    protocol       = "TCP"
    description    = "Allow incoming MySQL connections"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3306
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing connections"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Создание кластера MySQL
resource "yandex_mdb_mysql_cluster" "netology_mysql_cluster" {
  name        = "netology-mysql-cluster"
  description = "MySQL cluster for Netology homework"
  environment = "PRESTABLE"
  network_id  = var.network_id
  version     = "8.0"

  # Защита от непреднамеренного удаления
  deletion_protection = true

  # Класс хостов: Intel Broadwell с производительностью 50% CPU
  resources {
    resource_preset_id = "b1.medium"  # 2 vCPU (50% Intel Broadwell), 4 GB RAM
    disk_type_id       = "network-ssd"
    disk_size          = 20           # Размер диска 20 ГБ
  }

  # Настройки резервного копирования
  backup_window_start {
    hours   = 23
    minutes = 59
  }

  # Окно технического обслуживания (произвольное время)
  maintenance_window {
    type = "ANYTIME"
  }

  # Размещение хостов MySQL в разных подсетях и зонах доступности
  # для обеспечения отказоустойчивости
  host {
    zone             = "ru-central1-a"
    subnet_id        = yandex_vpc_subnet.mysql_subnet_a.id
    assign_public_ip = false
  }

  host {
    zone             = "ru-central1-b"
    subnet_id        = yandex_vpc_subnet.mysql_subnet_b.id
    assign_public_ip = false
  }

  host {
    zone             = "ru-central1-d"
    subnet_id        = yandex_vpc_subnet.mysql_subnet_d.id
    assign_public_ip = false
  }

  # Подключение группы безопасности
  security_group_ids = [yandex_vpc_security_group.mysql_security_group.id]

  # Настройки MySQL
  mysql_config = {
    sql_mode                      = "ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
    max_connections               = 100
    default_authentication_plugin = "MYSQL_NATIVE_PASSWORD"
  }
}

# Создание базы данных netology_db
resource "yandex_mdb_mysql_database" "netology_db" {
  cluster_id = yandex_mdb_mysql_cluster.netology_mysql_cluster.id
  name       = "netology_db"
}

# Создание пользователя БД с логином и паролем
resource "yandex_mdb_mysql_user" "netology_user" {
  cluster_id = yandex_mdb_mysql_cluster.netology_mysql_cluster.id
  name       = "netology_admin"
  password   = var.db_password  # Пароль из переменной

  # Предоставление прав доступа к базе данных
  permission {
    database_name = yandex_mdb_mysql_database.netology_db.name
    roles         = ["ALL"]
  }

  authentication_plugin = "MYSQL_NATIVE_PASSWORD"
}

# Переменная для пароля пользователя БД
variable "db_password" {
  description = "Password for MySQL user"
  type        = string
  sensitive   = true
}

# Outputs
output "cluster_id" {
  description = "MySQL cluster ID"
  value       = yandex_mdb_mysql_cluster.netology_mysql_cluster.id
}

output "cluster_name" {
  description = "MySQL cluster name"
  value       = yandex_mdb_mysql_cluster.netology_mysql_cluster.name
}

output "database_name" {
  description = "Database name"
  value       = yandex_mdb_mysql_database.netology_db.name
}

output "mysql_user" {
  description = "MySQL username"
  value       = yandex_mdb_mysql_user.netology_user.name
}

output "mysql_hosts" {
  description = "MySQL hosts information"
  value = [
    for host in yandex_mdb_mysql_cluster.netology_mysql_cluster.host : {
      fqdn = host.fqdn
      zone = host.zone
    }
  ]
}
```

## Файл terraform.tfvars

Создайте файл `terraform.tfvars` для значений переменных:

```hcl
yc_token     = "ваш_OAuth_токен"
yc_cloud_id  = "ваш_cloud_id"
yc_folder_id = "ваш_folder_id"
network_id   = "ваш_network_id_из_предыдущих_заданий"
db_password  = "надежный_пароль_минимум_8_символов"
```

**Важно**: не добавляйте файл `terraform.tfvars` в систему контроля версий, так как он содержит конфиденциальные данные.

## Инструкция по развертыванию

### 1. Подготовка

Убедитесь, что у вас установлены:
- Terraform версии >= 1.5.0
- Yandex Cloud CLI (yc)

### 2. Аутентификация

Получите OAuth-токен для Yandex Cloud:

```bash
yc iam create-token
```

### 3. Инициализация Terraform

```bash
terraform init
```

### 4. Проверка конфигурации

Проверьте синтаксис и план развертывания:

```bash
terraform validate
terraform plan
```

### 5. Применение конфигурации

Разверните инфраструктуру:

```bash
terraform apply
```

Подтвердите применение изменений, введя `yes`.

### 6. Просмотр результатов

После успешного развертывания будут выведены outputs с информацией о кластере:

- `cluster_id` - идентификатор кластера
- `cluster_name` - имя кластера
- `database_name` - имя базы данных (netology_db)
- `mysql_user` - имя пользователя БД
- `mysql_hosts` - информация о хостах (FQDN и зоны)

## Особенности конфигурации

### Отказоустойчивость

Кластер создается с тремя хостами в разных зонах доступности:
- **ru-central1-a** - первичный хост
- **ru-central1-b** - реплика
- **ru-central1-d** - реплика

При сбое одного хоста кластер продолжит работу на оставшихся хостах с автоматическим переключением на другой мастер.

### Репликация

Managed Service for MySQL автоматически настраивает репликацию между хостами. Параметр `maintenance_window` с типом `ANYTIME` позволяет Yandex Cloud выбирать оптимальное время для технического обслуживания.

### Резервное копирование

Резервное копирование настроено на 23:59 (UTC) ежедневно. Бэкапы сохраняются согласно политике по умолчанию Managed Service for MySQL.

### Безопасность

- **Группа безопасности** ограничивает доступ к порту 3306
- **Защита от удаления** (`deletion_protection = true`) предотвращает случайное удаление кластера
- **Пароль пользователя** хранится как sensitive переменная

### Класс хостов

Класс `b1.medium` предоставляет:
- 2 vCPU с производительностью 50% на платформе Intel Broadwell
- 4 GB RAM
- Подходит для тестовых и небольших production окружений

## Подключение к БД

После развертывания получите FQDN мастер-хоста из outputs и подключитесь:

```bash
mysql -h <FQDN_хоста> -P 3306 -u netology_admin -p netology_db
```

Или через приложение:

```
Host: <FQDN_хоста>
Port: 3306
Database: netology_db
Username: netology_admin
Password: <ваш_пароль_из_terraform.tfvars>
```

## Удаление инфраструктуры

Для удаления кластера необходимо:

1. Отключить защиту от удаления в конфигурации:
   ```hcl
   deletion_protection = false
   ```

2. Применить изменения:
   ```bash
   terraform apply
   ```

3. Удалить все ресурсы:
   ```bash
   terraform destroy
   ```

## Дополнительные настройки

### Изменение размера диска

Чтобы увеличить размер диска, измените параметр `disk_size` в блоке `resources`:

```hcl
resources {
  resource_preset_id = "b1.medium"
  disk_type_id       = "network-ssd"
  disk_size          = 50  # Увеличить до 50 ГБ
}
```

### Изменение класса хостов

Для повышения производительности можно использовать другие классы:

- `s1.micro` - 2 vCPU 100%, 8 GB RAM
- `s1.small` - 4 vCPU 100%, 16 GB RAM
- `s1.medium` - 8 vCPU 100%, 32 GB RAM

### Настройка окна обслуживания

Для установки конкретного времени обслуживания:

```hcl
maintenance_window {
  type = "WEEKLY"
  day  = "SUN"
  hour = 2
}
```

## Мониторинг

После создания кластера доступны:

- **Консоль Yandex Cloud** - графики производительности, состояние хостов
- **Логи** - в разделе "Логи" кластера
- **Метрики** - CPU, память, диск, сетевые операции

## Справочные материалы

- [Yandex Cloud MySQL Documentation](https://cloud.yandex.ru/docs/managed-mysql/)
- [Terraform Provider Yandex Cloud](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs)
- [MySQL Host Classes](https://cloud.yandex.ru/docs/managed-mysql/concepts/instance-types)
- [Replication in MySQL](https://cloud.yandex.ru/docs/managed-mysql/concepts/replication)
