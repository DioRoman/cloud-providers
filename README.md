# Terraform Yandex Cloud LAMP Infrastructure

***

## Описание

Проект автоматизирует развертывание LAMP-инфраструктуры в **Yandex Cloud**, используя Terraform.  
Включает создание виртуальных сетей, подсетей, NAT-инстанса, публичных и приватных ВМ, группу инстансов с автоскейлингом, балансировщик нагрузки (NLB) и Object Storage (аналог S3) с публичным доступом к изображению.

Архитектура ориентирована на развёртывание LAMP-сервера с веб-доступом через балансировщик и интернет-доступом для приватных ВМ через NAT.

***

## Компоненты инфраструктуры

- **VPC и подсети**
  - Публичная подсеть (`192.168.10.0/24`)
  - Приватная подсеть (`192.168.20.0/24`)
  - Таблица маршрутизации для выхода приватных хостов через NAT-инстанс

- **Группы безопасности**
  - Разрешены порты 22 (SSH), 80 (HTTP), 443 (HTTPS), ICMP

- **Инстансы и группы**
  - **Instance Group** `vm_public_group`:  
    Автоматически управляемая группа из LAMP-серверов с шаблоном cloud-init (`vm-lamp.yml`).  
    Использует балансировщик для HTTP-запросов.
  - **vm_private**: Приватная VM в подсети без NAT.
  - **vm_nat**: NAT-инстанс для доступа приватных хостов в интернет.

- **Load Balancer**
  - `yandex_lb_network_load_balancer.web_nlb` слушает порт 80 и проверяет здоровье LAMP-инстансов.
  - Привязан к статическому IP (`yandex_vpc_address.nlb_external_ip`).

- **Object Storage**
  - Публичный бакет с загружаемым изображением (`image.jpg`).
  - HTML-файл на LAMP-серверах ссылается на это изображение через публичный URL.

***

## Файлы проекта

| Файл | Описание |
|------|-----------|
| `main.tf` | Основная конфигурация Terraform |
| `vm-lamp.yml` | cloud-init для LAMP-инстансов (создает страницу с публичным изображением) |
| `vm.yml` | cloud-init для базовой конфигурации ВМ |
| `variables.tf` | Переменные окружения и параметры ВМ |
| `outputs.tf` | Вывод IP-адресов, URL и других значений |
| `backend` | Конфигурация S3 backend для хранения состояния |
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

- `nlb_ip` — внешний IP балансировщика (используйте в браузере)
- `vm_nat_ips` — внутренние IP NAT-инстансов
- `vm_private_ips` — внутренние IP приватных ВМ
- `bucket_name` — имя созданного бакета
- `image_object_url` — публичный URL изображения в Object Storage

***

## Подготовка окружения

1. Установите **Terraform ≥1.8**  
2. Настройте Yandex Cloud CLI и создайте сервисный аккаунт:
   ```bash
   yc init
   yc iam service-account create --name terraform-sa
   yc iam key create --service-account-name terraform-sa --output ~/.authorized_key.json
   ```
3. Экспортируйте переменные:
   ```bash
   export YC_CLOUD_ID=loud_idid>
   export YC_FOLDER_ID=<folder_id>
   ```
4. Убедитесь, что SSH-ключ сгенерирован:
   ```bash
   ssh-keygen -t ed25519
   ```

***

## Развёртывание

```bash
terraform init
terraform plan
terraform apply
```

После завершения откройте в браузере:

```
http://<nlb_ip>
```

Вы увидите страницу с загруженным изображением из Object Storage.

***

## Удаление ресурсов

Чтобы полностью очистить окружение:

```bash
terraform destroy
```

Это удалит все созданные ресурсы, включая ВМ, сеть, балансировщик и бакет.

***

## Автор

**Dio Roman**  
Terraform + Yandex Cloud Infrastructure Automation  
GitHub: [github.com/DioRoman](https://github.com/DioRoman)