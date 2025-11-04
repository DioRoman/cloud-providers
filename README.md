# Terraform Yandex Cloud LAMP Infrastructure

***

## Описание

Проект автоматизирует развертывание LAMP-инфраструктуры в **Yandex Cloud**, используя Terraform.  
Включает создание виртуальных сетей, подсетей, NAT-инстанса, публичных и приватных ВМ, группу инстансов с автоскейлингом, балансировщик нагрузки (NLB) и Object Storage (аналог S3) с публичным доступом к изображению.

Архитектура ориентирована на развёртывание LAMP-сервера с веб-доступом через балансировщик и интернет-доступом для приватных ВМ через NAT.

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

<img width="1527" height="450" alt="Снимок экрана 2025-11-04 182958" src="https://github.com/user-attachments/assets/c2f9db80-7859-42f4-86d1-5dcaee16c90e" />

<img width="1646" height="265" alt="Снимок экрана 2025-11-04 183007" src="https://github.com/user-attachments/assets/57ed409d-a583-4d4f-9a6a-49aee0645912" />

- **Load Balancer**
  - `yandex_lb_network_load_balancer.web_nlb` слушает порт 80 и проверяет здоровье LAMP-инстансов.
  - Привязан к статическому IP (`yandex_vpc_address.nlb_external_ip`).

<img width="1199" height="228" alt="Снимок экрана 2025-11-04 183023" src="https://github.com/user-attachments/assets/4b179be6-df88-41d1-8e45-721af858146f" />

<img width="753" height="1162" alt="Снимок экрана 2025-11-04 183052" src="https://github.com/user-attachments/assets/5321b444-862f-4f9d-9482-68d4ba90fc96" />

- **Object Storage**
  - Публичный бакет с загружаемым изображением (`image.jpg`).
  - HTML-файл на LAMP-серверах ссылается на это изображение через публичный URL.

<img width="857" height="326" alt="Снимок экрана 2025-11-04 134102" src="https://github.com/user-attachments/assets/0f2b71bb-86ac-4353-abb7-451ff2a5b21f" />

<img width="976" height="257" alt="Снимок экрана 2025-11-04 134107" src="https://github.com/user-attachments/assets/b70db29c-58a8-4f1f-82fd-37a5116a6ff1" />

***

## Файлы проекта

| Файл | Описание |
|------|-----------|
| `main.tf` | Основная конфигурация Terraform |
| `vm-lamp.yml` | cloud-init для LAMP-инстансов (создает страницу с публичным изображением) |
| `vm.yml` | cloud-init для базовой конфигурации ВМ |
| `variables.tf` | Переменные окружения и параметры ВМ |
| `outputs.tf` | Вывод IP-адресов, URL и других значений |
| `s3bucket.tf` | Конфигурация S3 backend для хранения состояния |
| `loadbalancer.tf` | Конфигурация netvork load balancer |
| `vars_modules.tf` | Переменные VM |
| `instance_group.tf` | Создание instance group |
| `providers.tf` | Подлючение к провайдеру |
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

<img width="468" height="546" alt="Снимок экрана 2025-11-04 145206" src="https://github.com/user-attachments/assets/c054c299-57e9-4bb3-986f-b0300da384c5" />

Вы увидите страницу с загруженным изображением из Object Storage.

***

## Тестирование отказоустойчивости

Чтобы убедиться, что инфраструктура корректно справляется с отказами, выполните следующие проверки:

### Проверка отказа LAMP-инстанса

1. Получите список ВМ в группе:
   ```bash
   yc compute instance-group list-instances --name vm-public-group
   ```
2. Остановите одну из машин:
   ```bash
   yc compute instance stop <instance-id>
   ```
   
<img width="1533" height="460" alt="Снимок экрана 2025-11-04 183233" src="https://github.com/user-attachments/assets/36655ca6-f502-4642-974e-d47857d2b790" />

3. Подождите 1–2 минуты и откройте в браузере `http://<nlb_ip>`.

**Результат:** веб-страница продолжает открываться — трафик перенаправлен на оставшиеся инстансы.

<img width="1565" height="62" alt="Снимок экрана 2025-11-04 183301" src="https://github.com/user-attachments/assets/567d168f-0c9c-4063-b16d-911bda755a8f" />

4. Проверьте, что Instance Group автоматически восстановила остановленный инстанс:
   ```bash
   yc compute instance-group list-instances --name vm-public-group
   ```
   Новый инстанс должен автоматически появиться, а старый — перейти в статус `DELETING` или `STOPPED`.

<img width="750" height="474" alt="Снимок экрана 2025-11-04 183324" src="https://github.com/user-attachments/assets/36bc6517-0890-40d5-a3d0-d03a4402f6e3" />

<img width="1547" height="445" alt="Снимок экрана 2025-11-04 183332" src="https://github.com/user-attachments/assets/6b186c45-20f8-46cc-9cab-87ec8b8eff8e" />

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
