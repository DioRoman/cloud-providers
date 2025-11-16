# Высокодоступный Kubernetes кластер в Yandex Cloud

Полнофункциональный проект Infrastructure-as-Code для развёртывания высокодоступного Kubernetes кластера в Yandex Cloud с поддержкой шифрования данных, MySQL базой данных и phpMyAdmin интерфейсом управления.

## 📋 Описание проекта

Этот проект автоматизирует развёртывание и управление следующими компонентами:

- **Kubernetes кластер (HA)**: Управляемый кластер Kubernetes в трёх зонах доступности (ru-central1-a, ru-central1-b, ru-central1-d)

<img width="1229" height="299" alt="Снимок экрана 2025-11-15 171801" src="https://github.com/user-attachments/assets/098fa23d-3fc5-428f-9a8f-dfb7efd87305" />

- **Сетевая инфраструктура**: VPC с подсетями в каждой зоне, security groups и NAT
- **Шифрование**: KMS ключ для шифрования Kubernetes secrets
- **Базы данных**: MySQL Pod с persistent storage
- **Управление БД**: phpMyAdmin Deployment с LoadBalancer Service
- **Идентификация**: IAM Service Account с необходимыми ролями
- **Состояние**: Управление состоянием через S3 + DynamoDB

## 🏗️ Архитектура

### Сетевая топология

```
┌─────────────────────────────────────────────────────────┐
│              Yandex Cloud VPC (10.0.0.0/8)             │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────┐  ┌──────────────────┐             │
│  │   Subnet Zone A  │  │   Subnet Zone B  │  Zone D ...│
│  │  (10.5.0.0/16)   │  │  (10.6.0.0/16)   │             │
│  │  ru-central1-a   │  │  ru-central1-b   │             │
│  └──────────────────┘  └──────────────────┘             │
│       │                      │                          │
│       └──────────┬───────────┘                          │
│                  │                                      │
│          ┌───────▼────────┐                             │
│          │  K8s Cluster   │                             │
│          │  (10.1.0.0/16) │                             │
│          └────────────────┘                             │
│                  │                                      │
│          ┌───────▼────────┐                             │
│          │  Services      │                             │
│          │  (10.2.0.0/16) │                             │
│          └────────────────┘                             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Компоненты Kubernetes

```
┌─────────────────────────────────────────────────────────┐
│            Kubernetes Cluster (k8s-ha-cluster)          │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Master (Control Plane)                                 │
│  └─ Version: 1.32                                       │
│  └─ Auto-upgrade: Enabled                               │
│  └─ Maintenance Window: Sunday 22:00-01:00 (3h)         │
│                                                          │
│  Node Groups (3 zones):                                 │
│  ├─ k8s-node-group-ru-central1-a                        │
│  │  └─ Specs: 4 cores, 2GB RAM (50% preemptible)       │
│  │  └─ Min: 1, Max: 3, Initial: 1                       │
│  ├─ k8s-node-group-ru-central1-b                        │
│  │  └─ Same specs as Zone A                             │
│  └─ k8s-node-group-ru-central1-d                        │
│     └─ Same specs as Zone A                             │
│                                                          │
│  Workloads:                                             │
│  ├─ mysql (Pod)                                         │
│  │  └─ Service: mysql.default.svc.cluster.local:3306   │
│  │  └─ Type: ClusterIP                                  │
│  ├─ phpmyadmin (Deployment)                             │
│  │  └─ Service: LoadBalancer (external IP)              │
│  │  └─ Replicas: 1                                      │
│  └─ Volumes:                                            │
│     └─ mysql-storage (EmptyDir)                         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## 📁 Структура проекта

```
.
├── encrypt.tf                 # KMS ключи для шифрования
├── master_k8s.tf             # Конфигурация Control Plane Kubernetes
├── nodes_k8s.tf              # Конфигурация Node Groups
├── network.tf                # Сетевая инфраструктура (VPC, Security Groups)
├── mysql.tf                  # MySQL Pod и Service
├── phpmyadmin.tf             # phpMyAdmin Deployment и Service
├── service-account.tf        # IAM Service Account и Role Bindings
├── providers.tf              # Backend (S3 + DynamoDB), Providers
├── variables.tf              # Переменные проекта
├── outputs.tf                # Выходные значения
├── terraform.tfvars          # Значения переменных (not committed)
└── README.md                 # Этот файл
```

## 🔐 Безопасность

### KMS шифрование

Проект использует Yandex KMS для шифрования Kubernetes secrets:

```hcl
resource "yandex_kms_symmetric_key" "k8s_encryption_key" {
  name                = "k8s-secrets-encryption-key"
  description         = "KMS key for Kubernetes secrets encryption"
  default_algorithm   = "AES_128"
  rotation_period     = "8760h"  # 1 год
  labels              = {
    purpose = "kubernetes"
    type    = "cluster-encryption"
  }
}
```

**Параметры:**
- **Алгоритм**: AES_128 (Advanced Encryption Standard 128-bit)
- **Период ротации**: 8760 часов (1 год)
- **Автоматическая ротация**: Включена

### Security Groups

Security Group `k8s-security-group` содержит следующие правила:

| Порт | Протокол | Источник | Назначение |
|------|----------|----------|-----------|
| 0-65535 | TCP | Cluster + Service CIDR + Суbnets + 91.204.150.0/24 | Межузловое взаимодействие |
| 80 | TCP | 0.0.0.0/0 | HTTP для phpMyAdmin |
| 443 | TCP | 0.0.0.0/0 | HTTPS для API |
| 6443 | TCP | 0.0.0.0/0 | Kubernetes API Server |
| 10256 | TCP | 0.0.0.0/0 | kubelet API |
| 3306 | TCP | 0.0.0.0/0 | MySQL |
| 22 | TCP | 0.0.0.0/0 | SSH доступ |

**Исходящий трафик**: Разрешён весь трафик (ANY)

### IAM Service Account

Сервис-аккаунт `k8s-cluster-sa` имеет следующие роли:

- `k8s.clusters.agent` - Управление Kubernetes кластером
- `vpc.publicAdmin` - Управление VPC и публичными IP
- `container-registry.images.puller` - Загрузка образов контейнеров
- `kms.keys.encrypterDecrypter` - Использование KMS ключей
- `logging.writer` - Запись логов
- `load-balancer.admin` - Управление Load Balancers

### Kubernetes Secrets

MySQL пароль хранится в Kubernetes Secret и используется как для ROOT_PASSWORD, так и для phpMyAdmin:

```hcl
resource "kubernetes_secret" "mysql-password" {
  metadata {
    name = "mysql-password"
  }
  data = {
    password = base64encode(var.mysql_password)
  }
}
```

⚠️ **Важно**: В production следует использовать более безопасные способы управления secrets (например, Sealed Secrets, HashiCorp Vault).

## 🚀 Установка и развёртывание

### Предварительные требования

- **Terraform** >= 1.8
- **Yandex CLI** (`yc` command)
- **kubectl** >= 1.24
- **AWS CLI** (для работы с S3 и DynamoDB)
- Аккаунт в Yandex Cloud с соответствующими правами
- Авторизационный ключ JSON для Service Account

### Шаг 1: Подготовка окружения

Создайте авторизационный ключ для Service Account:

```bash
yc iam service-account create --name terraform-sa
yc iam folder-service-account add-access-binding b1g22qi1cc8rq4avqgik \
  --service-account-name terraform-sa \
  --role admin

yc iam service-account-key create \
  --service-account-name terraform-sa \
  --output ~/.authorized_key.json
```

Создайте AWS credentials для S3/DynamoDB:

```bash
yc iam access-key create --service-account-name terraform-sa
# Сохраните Key ID и Secret Key
```

Настройте AWS CLI:

```bash
mkdir -p ~/.aws
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = <KEY_ID>
aws_secret_access_key = <SECRET_KEY>
EOF

cat > ~/.aws/config << EOF
[default]
region = ru-central1
EOF
```

### Шаг 2: Инициализация Terraform

```bash
terraform init
```

Terraform инициализирует backend, создаст необходимые директории и загрузит providers.

### Шаг 3: Планирование развёртывания

```bash
terraform plan -out=tfplan
```

Этот команда показывает все изменения, которые будут выполнены.

### Шаг 4: Развёртывание

```bash
terraform apply tfplan
```

Развёртывание может занять 20-30 минут. Terraform создаст:
- VPC сеть с 3 подсетями

<img width="1889" height="529" alt="Снимок экрана 2025-11-15 171754" src="https://github.com/user-attachments/assets/54f717d2-7b3f-462d-b4ed-f776f95c0f3a" />

- Security Groups
- KMS ключ
- Kubernetes кластер с Control Plane

<img width="899" height="761" alt="Снимок экрана 2025-11-15 171814" src="https://github.com/user-attachments/assets/e93b50ea-5993-44b5-9102-47e1a2313fbd" />

- 3 Node Groups (по одной в каждой зоне)

<img width="1506" height="389" alt="Снимок экрана 2025-11-15 171825" src="https://github.com/user-attachments/assets/bdb34e2f-242e-421f-8c73-9b8e90f2eb25" />

- MySQL Pod с Service
- phpMyAdmin Deployment с LoadBalancer


### Шаг 5: Конфигурация kubectl

```bash
$(terraform output -raw kubeconfig_command)
# или вручную:
yc managed-kubernetes cluster get-credentials ha-k8s-cluster --external
```

Проверка доступа:

```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces
```

## 📤 Выходные значения (Outputs)

После успешного развёртывания получить следующие значения:

```bash
# ID кластера
terraform output cluster_id

# Имя кластера
terraform output cluster_name

# ID KMS ключа
terraform output kms_key_id

# ID Service Account
terraform output service_account_id

# ID VPC сети
terraform output network_id

# Команда для конфигурации kubectl
terraform output kubeconfig_command

# Endpoint Kubernetes API Server
terraform output master_endpoint

# CA сертификат (чувствительные данные)
terraform output master_ca_certificate

# Endpoint MySQL внутри кластера
terraform output mysql_endpoint

# URL phpMyAdmin
terraform output phpmyadmin_url

# Статус кластера
terraform output cluster_status
```

<img width="1776" height="952" alt="Снимок экрана 2025-11-15 162010" src="https://github.com/user-attachments/assets/dff2a0c3-faad-476b-8d01-40e375085629" />

## 💾 Backend состояния (S3 + DynamoDB)

Terraform состояние хранится в S3 бакете `dio-bucket` в Yandex Object Storage:

### Блокировка состояния

DynamoDB таблица `dio-bucket-lock-01` обеспечивает распределённую блокировку состояния, предотвращая одновременные применения конфигурации разными пользователями.

## 🔧 Управление кластером

### Добавление Worker Nodes

Масштабирование выполняется автоматически благодаря auto-scaling политике:

```hcl
scale_policy {
  auto_scale {
    min     = 1      # Минимум nodes
    max     = 3      # Максимум nodes
    initial = 1      # Начальное количество
  }
}
```

Для изменения лимитов отредактируйте `variables.tf` и выполните `terraform apply`.

### Обновление Kubernetes версии

Обновите переменную:

```bash
terraform apply -var="k8s_version=1.33"
```

Мастер и ноды обновятся в maintenance window (Sunday 22:00-01:00).

### Обновление MySQL

Для обновления MySQL образа:

```bash
terraform apply -var="mysql_image=mysql:8.4"
```

Pod будет пересоздан с новым образом.

## 📡 Доступ к сервисам

### MySQL

**Внутри кластера (для приложений):**
```
mysql.default.svc.cluster.local:3306
Username: db-user
Password: <mysql_password из variables>
Database: db-test
```

**Извне кластера (если Public IP настроен):**
```bash
# Найти Public IP ноды
kubectl get nodes -o wide

# Подключиться через MySQL Client
mysql -h <NODE_PUBLIC_IP> -u db-user -p -D db-test
```

### phpMyAdmin

**Получить URL:**
```bash
terraform output phpmyadmin_url
```

**Доступ:**
- URL: http://<LOAD_BALANCER_IP>
- Username: db-user
- Password: <mysql_password из variables>

### Kubernetes API

**Endpoint:**
```bash
terraform output master_endpoint
```

**Доступ через kubectl:**
```bash
kubectl cluster-info
```

## 🔄 Обслуживание и мониторинг

### Maintenance Windows

**Master:**
- День: Sunday (воскресенье)
- Время: 22:00 - 01:00 (3 часа)
- Auto-upgrade: Enabled

**Worker Nodes:**
- День: Sunday
- Время: 23:00 - 01:00 (2 часа)
- Auto-repair: Enabled
- Auto-upgrade: Enabled

### Проверка состояния

```bash
# Статус кластера
kubectl cluster-info

# Статус нод
kubectl get nodes -o wide

# Статус подов
kubectl get pods -A

# Логи mysql пода
kubectl logs mysql

# Логи phpmyadmin
kubectl logs -l app=phpmyadmin
```

### Масштабирование

Текущая конфигурация использует preemptible ноды (economy класс) для экономии затрат:

```hcl
scheduling_policy {
  preemptible = true  # Экономичные ноды, могут быть прерваны
}
```

Для production рекомендуется использовать стандартные ноды:

```hcl
scheduling_policy {
  preemptible = false
}
```

<img width="1882" height="1061" alt="Снимок экрана 2025-11-15 171932" src="https://github.com/user-attachments/assets/2555090a-b518-48e6-9c72-6b4d007970d7" />

## ⚠️ Важные замечания

### Production vs Development

Текущая конфигурация оптимизирована для обучения и тестирования:

| Параметр | Current | Production |
|----------|---------|-----------|
| MySQL Storage | EmptyDir (теряется) | PersistentVolume |
| MySQL Replicas | 1 | 3+ (для HA) |
| Preemptible Nodes | true | false |
| Backup | Отсутствует | Настроен |
| Secrets Management | Kubernetes Secret | Vault/Sealed Secrets |
| Monitoring | Отсутствует | Prometheus + Grafana |

### Безопасность

**Необходимые изменения для production:**

1. **Изменить пароль MySQL** в `variables.tf`
2. **Использовать PersistentVolume** вместо EmptyDir
3. **Настроить RBAC** для приложений
4. **Включить Network Policies** для изоляции трафика
5. **Использовать Sealed Secrets** для хранения credentials
6. **Ограничить доступ** к Security Group (уберите 0.0.0.0/0)
7. **Включить логирование и мониторинг**

## 🗑️ Удаление ресурсов

Для удаления всех созданных ресурсов:

```bash
terraform destroy
```

⚠️ **Внимание**: Эта команда удалит:
- Kubernetes кластер
- Все Node Groups
- VPC и подсети
- Security Groups
- KMS ключ
- MySQL Pod и Storage
- phpMyAdmin Deployment

Состояние останется в S3 бакете. Для полного удаления состояния:

```bash
aws s3 rm s3://dio-bucket/terraform-learning/terraform.tfstate --profile default
```

## 📖 Дополнительные ресурсы

- **Yandex Cloud Documentation**: https://cloud.yandex.ru/docs
- **Terraform Yandex Provider**: https://registry.terraform.io/providers/yandex-cloud/yandex
- **Kubernetes Official Docs**: https://kubernetes.io/docs
- **Yandex KMS**: https://cloud.yandex.ru/docs/kms/

## 📝 Лицензия

Этот проект является учебным материалом и доступен для использования в образовательных целях.

## 👤 Автор

Проект создан как часть курса DevOps/Kubernetes на Netology.

---

**Последнее обновление**: Ноябрь 2025
**Версия Terraform**: >= 1.8
**Версия Kubernetes**: 1.32
