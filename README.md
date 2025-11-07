# Terraform Yandex Cloud LAMP Infrastructure

***

## Описание

Проект автоматизирует развертывание LAMP-инфраструктуры в **Yandex Cloud**, используя Terraform.  
Включает создание виртуальных сетей, подсетей, NAT-инстанса, публичных и приватных ВМ, группу инстансов с автоскейлингом, балансировщик нагрузки (NLB) и Object Storage (аналог S3) с публичным доступом к изображению.

Архитектура ориентирована на развёртывание LAMP-сервера с веб-доступом через балансировщик и интернет-доступом для приватных ВМ через NAT.

```
                           Интернет
                               │
                      ┌─────────────────┐
                      │   NLB (HTTP/80) │
                      │-----------------│
                      │ IP: <nlb_ip>    │
                      └─────────────────┘
                               │
               ┌───────────────┴───────────────┐
               │                               │
     ┌───────────────────────┐       ┌───────────────────────┐
     │  Публичная подсеть    │       │   Приватная подсеть   │
     │ CIDR: 192.168.10.0/24 │       │ CIDR: 192.168.20.0/24 │
     │ Zone: ru-central1-a   │       │ Zone: ru-central1-a   │
     │                       │       │                       │
     │  ┌─────────────────┐  │       │   ┌────────────────┐  │
     │  │ Instance Group  │◄─┘       │   │ Private VM     │  │
     │  │ LAMP Servers    │          │   │ Ubuntu Server  │  │
     │  │ (3 instances)   │          │   └────────────────┘  │
     │  │ HTML + image S3 │          │       │               │
     │  └─────────────────┘          │       │ default route │
     │             │                 │       ▼ via NAT       │
     │  ┌─────────────────┐          │   ┌──────────────────┐│
     │  │ NAT Instance    │──────────┘   │ Route Table      ││
     │  │ 192.168.10.254  │              │ 0.0.0.0/0 → NAT  ││
     │  └─────────────────┘              └──────────────────┘│
     └───────────────────────┘       └───────────────────────┘
                                              │
                                     ┌────────────────────┐
                                     │  Object Storage    │
                                     │  (S3-compatible)   │
                                     │  KMS Encrypted     │
                                     └────────────────────┘
```

***

## Компоненты инфраструктуры

### Сетевая инфраструктура

- **VPC и подсети**
  - Публичная подсеть (`192.168.10.0/24`)
  - Приватная подсеть (`192.168.20.0/24`)
  - Таблица маршрутизации для выхода приватных хостов через NAT-инстанс

- **Группы безопасности**
  - Разрешены порты 22 (SSH), 80 (HTTP), 443 (HTTPS), ICMP

### Вычислительные ресурсы

- **Инстансы и группы**
  - **Instance Group** `vm_public_group`:  
    Автоматически управляемая группа из LAMP-серверов с шаблоном cloud-init (`vm-lamp.yml`).  
    Использует балансировщик для HTTP-запросов.
  - **vm_private**: Приватная VM в подсети без NAT.
  - **vm_nat**: NAT-инстанс для доступа приватных хостов в интернет.

<img width="1527" height="450" alt="Снимок экрана 2025-11-04 182958" src="https://github.com/user-attachments/assets/c2f9db80-7859-42f4-86d1-5dcaee16c90e" />

<img width="1646" height="265" alt="Снимок экрана 2025-11-04 183007" src="https://github.com/user-attachments/assets/57ed409d-a583-4d4f-9a6a-49aee0645912" />

### Балансировка нагрузки

- **Load Balancer**
  - `yandex_lb_network_load_balancer.web_nlb` слушает порт 80 и проверяет здоровье LAMP-инстансов.
  - Привязан к статическому IP (`yandex_vpc_address.nlb_external_ip`).

<img width="1199" height="228" alt="Снимок экрана 2025-11-04 183023" src="https://github.com/user-attachments/assets/4b179be6-df88-41d1-8e45-721af858146f" />

<img width="753" height="1162" alt="Снимок экрана 2025-11-04 183052" src="https://github.com/user-attachments/assets/5321b444-862f-4f9d-9482-68d4ba90fc96" />

### Object Storage и шифрование

- **Object Storage**
  - Публичный бакет с загружаемым изображением (`image.jpg`).
  - HTML-файл на LAMP-серверах ссылается на это изображение через публичный URL.
  - **Шифрование на стороне сервера**: Все объекты в бакете шифруются с использованием Yandex KMS.

- **KMS (Key Management Service)**
  - Симметричный ключ шифрования (`bucket-encryption-key`)
  - Алгоритм: AES-256
  - Автоматическая ротация ключа каждую неделю (168 часов)
  - Интеграция с Object Storage для прозрачного шифрования/дешифрования

<img width="857" height="326" alt="Снимок экрана 2025-11-04 134102" src="https://github.com/user-attachments/assets/0f2b71bb-86ac-4353-abb7-451ff2a5b21f" />

<img width="976" height="257" alt="Снимок экрана 2025-11-04 134107" src="https://github.com/user-attachments/assets/b70db29c-58a8-4f1f-82fd-37a5116a6ff1" />

***

## Безопасность

### Шифрование данных

Проект использует **Yandex KMS** для защиты данных в Object Storage:

- **Шифрование в покое (at-rest encryption)**:
  - Все объекты в бакете автоматически шифруются при сохранении
  - Дешифрование происходит прозрачно при чтении объектов
  - Используется алгоритм AES-256

- **Управление ключами**:
  - Ключи управляются централизованно через Yandex KMS
  - Автоматическая ротация ключей каждую неделю
  - Разделение обязанностей: доступ к ключам контролируется IAM

- **Соответствие требованиям**:
  - Защита конфиденциальных данных
  - Соответствие стандартам безопасности (GDPR, PCI DSS)
  - Аудит доступа к ключам через Cloud Logging

### Рекомендации по продакшену

⚠️ **Для продакшен-окружения рекомендуется**:

1. Включить защиту от удаления ключа:
   ```hcl
   resource "yandex_kms_symmetric_key" "bucket_key" {
     deletion_protection = true
     
     lifecycle {
       prevent_destroy = true
     }
   }
   ```

2. Настроить мониторинг использования ключей
3. Ограничить доступ к ключам через IAM-политики
4. Регулярно ротировать ключи (автоматическая ротация уже настроена)
5. Включить версионирование объектов в бакете

***

## Файлы проекта

| Файл | Описание |
|------|-----------|
| `main.tf` | Основная конфигурация Terraform, включая KMS-ключ |
| `vm-lamp.yml` | cloud-init для LAMP-инстансов (создает страницу с публичным изображением) |
| `vm.yml` | cloud-init для базовой конфигурации ВМ |
| `variables.tf` | Переменные окружения и параметры ВМ |
| `outputs.tf` | Вывод IP-адресов, URL, KMS-ключа и других значений |
| `s3bucket.tf` | Конфигурация S3 backend с поддержкой KMS-шифрования |
| `loadbalancer.tf` | Конфигурация network load balancer |
| `vars_modules.tf` | Переменные VM |
| `instance_group.tf` | Создание instance group |
| `providers.tf` | Подключение к провайдеру |
| `locals.tf` | Общие locals |
| `image.jpg` | Тестовая картинка |
| `modules/` | Используемые модули Terraform (подключаются из GitHub) |

***

## Переменные

Часть ключевых переменных определена в секции `variable`:

| Имя | Назначение | Значение по умолчанию |
|------|-------------|------------------------|
| `cloud_id` | ID облака Yandex Cloud | `"b1g2uh898q9ekgq43tfq"` |
| `folder_id` | ID каталога | `"b1g22qi1cc8rq4avqgik"` |
| `bucket_name` | Имя создаваемого бакета | `"dio-new-bucket-20251104"` |
| `vm_lamp_image` | ID образа для LAMP | `"fd8na0csfs8r1mb91trm"` |
| `vm_nat_image` | ID образа NAT-инстанса | `"fd8hqm1si8i5ul8v396c"` |
| `vm_web_image_family` | Семейство образов Ubuntu | `"ubuntu-2404-lts"` |
| `vm_ssh_root_key` | Путь к публичному SSH-ключу | `"~/.ssh/id_ed25519.pub"` |

***

## Выводимые параметры

После успешного применения (`terraform apply`) Terraform выведет:

### Сетевые параметры
- `nlb_ip` — внешний IP балансировщика (используйте в браузере)
- `vm_nat_ips` — внутренние IP NAT-инстансов
- `vm_private_ips` — внутренние IP приватных ВМ
- `vm_public_group_external_ips` — список внешних IP-адресов всех инстансов в публичной группе (формат: `http://<IP>`)

### Storage параметры
- `bucket_name` — имя созданного бакета
- `image_object_url` — публичный URL изображения в Object Storage

### Безопасность
- `kms_key_id` — ID KMS-ключа для шифрования бакета

**Пример вывода**:
```bash
Outputs:

bucket_name = "dio-new-bucket-20251104"
image_object_url = "https://storage.yandexcloud.net/dio-new-bucket-20251104/image.jpg"
kms_key_id = "abjc1d2e3f4g5h6i7j8k"
nlb_ip = "http://51.250.12.34"
vm_nat_ips = [
  "192.168.10.254",
]
vm_private_ips = [
  "192.168.20.10",
]
vm_public_group_external_ips = [
  "http://51.250.15.100",
  "http://51.250.15.101",
  "http://51.250.15.102",
]
```

***

## Подготовка окружения

### Требования

- **Terraform** ≥ 1.8
- **Yandex Cloud CLI** (yc)
- SSH-ключ для доступа к ВМ

## Развёртывание

### Инициализация и планирование

```bash
# Инициализация Terraform
terraform init

# Проверка конфигурации
terraform validate

# Предварительный просмотр изменений
terraform plan
```

### Применение конфигурации

```bash
# Развертывание инфраструктуры
terraform apply

# Или с автоподтверждением
terraform apply -auto-approve
```

### Проверка результата

После завершения развертывания (обычно 3-5 минут):

1. **Откройте балансировщик в браузере**:
   ```
   http://<nlb_ip>
   ```
   Вы увидите страницу с изображением, загруженным из зашифрованного Object Storage.

<img width="468" height="546" alt="Снимок экрана 2025-11-04 145206" src="https://github.com/user-attachments/assets/c054c299-57e9-4bb3-986f-b0300da384c5" />

2. **Проверьте доступность отдельных инстансов**:
   ```bash
   # Получите список IP из outputs
   terraform output vm_public_group_external_ips
   
   # Откройте любой из IP в браузере
   ```

3. **Проверьте шифрование бакета**:
   ```bash
   # Получите информацию о бакете
   yc storage bucket get <bucket_name>
   
   # Проверьте конфигурацию шифрования
   yc storage bucket get-encryption <bucket_name>
   ```

***

## Тестирование отказоустойчивости

### Проверка 1: Отказ LAMP-инстанса

1. Получите список ВМ в группе:
   ```bash
   yc compute instance-group list-instances --name vm-public-group
   ```

2. Остановите одну из машин:
   ```bash
   yc compute instance stop <instance-id>
   ```
   
<img width="1533" height="460" alt="Снимок экрана 2025-11-04 183233" src="https://github.com/user-attachments/assets/36655ca6-f502-4642-974e-d47857d2b790" />

3. Проверьте доступность сервиса:
   ```bash
   # Откройте в браузере
   curl http://<nlb_ip>
   ```

**Ожидаемый результат**: веб-страница продолжает открываться — трафик перенаправлен на оставшиеся инстансы.

<img width="1565" height="62" alt="Снимок экрана 2025-11-04 183301" src="https://github.com/user-attachments/assets/567d168f-0c9c-4063-b16d-911bda755a8f" />

4. Проверьте автоматическое восстановление:
   ```bash
   # Подождите 1-2 минуты
   yc compute instance-group list-instances --name vm-public-group
   ```
   Новый инстанс должен автоматически появиться.

<img width="750" height="474" alt="Снимок экрана 2025-11-04 183324" src="https://github.com/user-attachments/assets/36bc6517-0890-40d5-a3d0-d03a4402f6e3" />

<img width="1547" height="445" alt="Снимок экрана 2025-11-04 183332" src="https://github.com/user-attachments/assets/6b186c45-20f8-46cc-9cab-87ec8b8eff8e" />

***

## Масштабирование

### Изменение размера Instance Group

Отредактируйте `instance_group.tf`:

```hcl
scale_policy {
  fixed_scale {
    size = 5  # Увеличить до 5 инстансов
  }
}
```

Примените изменения:
```bash
terraform apply
```

### Автоматическое масштабирование (Auto-scaling)

Замените `fixed_scale` на `auto_scale`:

```hcl
scale_policy {
  auto_scale {
    min_zone_size          = 1
    max_size               = 10
    measurement_duration   = 60
    warmup_duration        = 120
    stabilization_duration = 300
    initial_size           = 3
    
    cpu_utilization_target = 70
  }
}
```

***

## Удаление ресурсов

### Полное удаление инфраструктуры

```bash
terraform destroy
```

### Поэтапное удаление

```bash
# 1. Удалить Instance Group
terraform destroy -target=yandex_compute_instance_group.vm_public_group

# 2. Удалить Load Balancer
terraform destroy -target=yandex_lb_network_load_balancer.web_nlb

# 3. Удалить все остальное
terraform destroy
```

### Важно

⚠️ **Перед удалением**:
- Сохраните важные данные из Object Storage
- Экспортируйте логи и метрики
- Сделайте снимки (snapshots) критичных дисков

⚠️ **KMS-ключ**: При `deletion_protection = false` ключ будет удален вместе с инфраструктурой. В продакшене установите `deletion_protection = true`.

***

## Полезные ссылки

- [Документация Yandex Cloud](https://cloud.yandex.ru/docs)
- [Terraform Yandex Provider](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs)
- [Yandex KMS Documentation](https://cloud.yandex.ru/docs/kms/)
- [Compute Instance Groups](https://cloud.yandex.ru/docs/compute/concepts/instance-groups/)
- [Network Load Balancer](https://cloud.yandex.ru/docs/network-load-balancer/)
- [Object Storage (S3)](https://cloud.yandex.ru/docs/storage/)

***

## Лицензия

MIT License

***

## Автор

**Dio Roman**  
Terraform + Yandex Cloud Infrastructure Automation  
GitHub: [github.com/DioRoman](https://github.com/DioRoman)

***

## Changelog

### v1.1.0 (2025-11-07)
- ✅ Добавлено KMS-шифрование для Object Storage
- ✅ Добавлен output для внешних IP Instance Group
- ✅ Автоматическая ротация KMS-ключей
- ✅ Расширена документация по безопасности

### v1.0.0 (2025-11-04)
- ✅ Базовая LAMP-инфраструктура
- ✅ Instance Group с автовосстановлением
- ✅ Network Load Balancer
- ✅ NAT-инстанс для приватных сетей
- ✅ Object Storage с публичным доступом