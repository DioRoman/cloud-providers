# Terraform Infrastructure — MySQL Cluster on Yandex Cloud

Этот проект автоматизирует создание высокодоступного кластера MySQL в **Yandex Cloud** с использованием **Terraform**. Инфраструктура включает:
- собственную VPC-сеть и подсети (публичную и приватные);
- группу безопасности с корректными ingress/egress-правилами;
- кластер MySQL Managed Database (MDB);
- создание базы данных и пользователя с безопасным управлением паролем через **Yandex Lockbox**;
- сохранение Terraform состояния в бакете Object Storage с блокировкой через DynamoDB (совместимый API).

***

## Содержание

- [Структура проекта](#структура-проекта)
- [Предварительные требования](#предварительные-требования)
- [Переменные](#переменные)
- [Установка и запуск](#установка-и-запуск)
- [Выходные данные](#выходные-данные)
- [Ротация пароля](#ротация-пароля)
- [Очистка ресурсов](#очистка-ресурсов)
- [Архитектура и топология](#архитектура-и-топология)

***

## Структура проекта

```
.
├── main.tf                 # Основная логика и ресурсы Terraform
├── variables.tf            # Переменные проекта
├── outputs.tf              # Выходные значения Terraform
├── providers.tf            # провайдеры и бэкенд Terraform
├── README.md               # Текущее описание
└── modules/
    └── yandex-vpc          # Git-модуль для создания сети, подсетей и групп безопасности
```

***

## Предварительные требования

Перед запуском убедитесь, что у вас настроена среда:

- **Terraform ≥ 1.8**
- **Yandex CLI** настроен и авторизован  
  Инструкция: [https://cloud.yandex.ru/docs/cli/quickstart](https://cloud.yandex.ru/docs/cli/quickstart)
- Создан **service account** с правами `editor`, `lockbox.editor`, `kms.keys.encrypterDecrypter`, `vpc.admin`, `mdb.admin`
- **Файл ключа сервисного аккаунта** расположен по пути `~/.authorized_key.json`
- **Object Storage bucket** и **DynamoDB совместимая таблица** уже существуют (для Terraform backend)

***

## Переменные

Некоторые ключевые параметры, доступные через `variables.tf` или `terraform.tfvars`:

| Переменная | Тип | Описание | Значение по умолчанию |
|-------------|-----|----------|------------------------|
| **cloud_id** | string | ID облака Yandex Cloud | `<твой cloud_id>` |
| **folder_id** | string | ID каталога | `<твой folder_id>` |
| **env_name** | string | Имя окружения (используется при именовании ресурсов) | `MYSQL-net` |
| **mysql_cluster_environment** | string | Среда развертывания MDB | `PRESTABLE` |
| **mysql_version** | string | Версия MySQL | `8.0` |
| **mysql_resource_preset_id** | string | Конфигурация ресурсов | `b1.medium` |
| **mysql_disk_type_id** | string | Тип дисков | `network-ssd` |
| **mysql_disk_size** | number | Размер диска (ГБ) | `20` |
| **mysql_password_version** | string | Версия (для ротации пароля) | `v1` |
| **db_password** | string | Заданный вручную пароль (опционально) | `""` (генерируется автоматически) |

***

## Установка и запуск

1. **Клонируйте репозиторий:**
   ```bash
   git clone https://github.com/<your-repo>/terraform-yc-mysql.git
   cd terraform-yc-mysql
   ```

2. **Проверьте переменные:**
   При необходимости измените значения по умолчанию в `variables.tf` или создайте свой `terraform.tfvars`.

3. **Инициализация Terraform:**
   ```bash
   terraform init
   ```

4. **Проверка планируемых изменений:**
   ```bash
   terraform plan
   ```

5. **Применение изменений:**
   ```bash
   terraform apply
   ```

6. **Подтверждение развертывания:**
   После успешного выполнения Terraform выведет параметры кластера (см. ниже).

***

## Выходные данные

| Имя | Описание |
|------|-----------|
| **cluster_id** | ID кластера MySQL |
| **cluster_name** | Имя кластера MySQL |
| **database_name** | Имя созданной базы данных |
| **mysql_user** | Имя пользователя базы данных |
| **mysql_hosts** | FQDN и зоны размещения хостов |
| **mysql_password_secret_id** | ID секрета Lockbox, где хранится пароль |

Пример вывода:
```
cluster_id = "c9q4abc123xyz"
cluster_name = "netology-mysql-cluster"
database_name = "netology_db"
mysql_user = "netology_admin"
mysql_hosts = [
  {
    fqdn = "rc1b-xyz123.mdb.yandexcloud.net"
    zone = "ru-central1-a"
  },
  {
    fqdn = "rc1c-xyz123.mdb.yandexcloud.net"
    zone = "ru-central1-b"
  }
]
```

***

## Ротация пароля

Пароль MySQL хранится в **Yandex Lockbox**.  
Чтобы сгенерировать новый пароль, измените значение переменной:

```hcl
mysql_password_version = "v2"
```

и выполните:
```bash
terraform apply
```

Terraform создаст новую версию секрета и обновит пользователя MySQL.

***

## Очистка ресурсов

Чтобы удалить инфраструктуру (если отключена защита от удаления):

```bash
terraform destroy
```

Если включена защита (`deletion_protection = true`), необходимо временно установить параметр:

```hcl
mysql_deletion_protection = false
mysql_secret_deletion_protection = false
```

***

## Архитектура и топология

Инфраструктура создаёт:

- VPC-сеть с тремя подсетями:
  - `public` — для общего доступа (можно подключить NAT или bastion);
  - `private-ru-central1-a` и `private-ru-central1-b` — приватные зоны для MySQL;
- Security Group *mysql* с разрешением на:
  - 22 (SSH)
  - 80 (HTTP)
  - 443 (HTTPS)
  - 3306 (MySQL)
  - ICMP (Ping)
- Кластер MySQL с 2 хостами в разных зонах для отказоустойчивости;
- Managed Lockbox Secret для безопасного хранения и ротации пароля;
- Terraform backend через Yandex Object Storage и DynamoDB для state-locking.