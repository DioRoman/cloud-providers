# Terraform — Yandex Cloud VPC, NAT-инстанс и VM

Этот проект создает инфраструктуру в **Yandex Cloud**, включающую сеть с публичной и приватной подсетями, NAT-инстанс для выхода из приватной сети в интернет, а также виртуальные машины, сгруппированные по ролям (public, private, nat).

***

## Структура

- **VPC и подсети**:
  - `public` — подсеть для внешних ресурсов (доступ к интернету).
  - `private` — подсеть без прямого доступа в интернет, использует NAT для исходящего трафика.

<img width="1438" height="232" alt="Снимок экрана 2025-11-03 191601" src="https://github.com/user-attachments/assets/fb289b74-6d4a-4a3b-8d53-09f517f3cdd6" />

<img width="1578" height="265" alt="Снимок экрана 2025-11-03 191613" src="https://github.com/user-attachments/assets/ccad2ba9-c5aa-429a-b823-3e052d9cfbfb" />

- **Security Groups**:
  - `web` — разрешает HTTP (80), HTTPS (443), SSH (22) и ICMP-трафик.
- **Виртуальные машины**:
  - `vm-public` — публичная VM с внешним IP.
  - `vm-private` — приватная VM без прямого доступа к интернету.
  - `vm-nat` — NAT-инстанс с публичным IP для маршрутизации исходящего трафика приватной сети.
 
<img width="1749" height="356" alt="Снимок экрана 2025-11-03 191549" src="https://github.com/user-attachments/assets/0e3c8370-9668-41e8-9212-7eed442b6c77" />

- **Route table**:
  - `private-route-table` — направляет исходящий трафик из приватной сети на NAT-инстанс.

<img width="1877" height="461" alt="Снимок экрана 2025-11-03 191652" src="https://github.com/user-attachments/assets/2bd15aaa-6b95-40fc-87ec-7d0ac818e025" />

***

## Предварительные требования

1. **Terraform ≥ 1.8.0**  
2. **CLI-инструменты**:  
   - `yc` — для управления облаком Yandex Cloud  
   - `yq`/`jq` — для работы с YAML/JSON
3. **Сервисный аккаунт** с достаточными правами (`editor` или выше).  
   Скачай ключ:
   ```bash
   yc iam key create --service-account-name <sa-name> --output ~/.authorized_key.json
   ```
4. **SSH-ключ** для доступа к виртуальным машинам:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
   ```

***

## Переменные

| Имя                     | Описание                                                | Значение по умолчанию |
|--------------------------|----------------------------------------------------------|------------------------|
| `cloud_id`               | ID облака                                               | `b1g2uh898q9ekgq43tfq` |
| `folder_id`              | ID каталога                                             | `b1g22qi1cc8rq4avqgik` |
| `vpc_default_zone`       | Список доступных зон                                    | `[a, b, d]` |
| `vm_web_image_family`    | Образ для VM                                            | `ubuntu-2404-lts` |
| `vm_ssh_root_key`        | Путь к SSH-ключу                                        | `~/.ssh/id_ed25519.pub` |
| `vm_nat_image`           | Образ для NAT                                           | `fd8hqm1si8i5ul8v396c` |

***

## Модули

- **`yandex-vpc`** — создает сеть, подсети, таблицы маршрутов и security groups.  
- **`vm_public`**, **`vm_private`**, **`vm_nat`** — модульные шаблоны создания ВМ.

***

## Настройка backend

Хранение состояния Terraform (`terraform.tfstate`) реализовано через **Yandex Object Storage (S3 back-end)** с блокировками в **DynamoDB API**:

```hcl
backend "s3" {
  bucket = "dio-bucket"
  key    = "terraform-learning/terraform.tfstate"
  region = "ru-central1"
}
```

***

## Развертывание

```bash
# Инициализация провайдеров и модулей
terraform init

# Проверка конфигурации
terraform validate

# Предпросмотр плана изменений
terraform plan

# Применение конфигурации
terraform apply
```

***

## Cloud-config

Виртуальные машины автоматически настраиваются с помощью `cloud-init`:
```yaml
users:
  - name: ubuntu
    groups: sudo
    shell: /bin/bash
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    ssh_authorized_keys:
      - ${ssh_public_key}

package_update: true
package_upgrade: true
packages:
  - mc
```

***

## Outputs

| Имя output | Описание | Пример |
|-------------|-----------|--------|
| `vm_public_ips` | Внутренние IP публичных ВМ | `192.168.10.10` |
| `vm_nat_ips` | IP NAT-инстансов | `192.168.10.254` |
| `vm_private_ips` | Внутренние IP приватных ВМ | `192.168.20.10` |
| `vm_public_ssh` | Готовые SSH-команды для подключения | `ssh -l ubuntu <ip>` |

***

## Проверка подключения

После развертывания можно подключиться:
```bash
terraform output vm_public_ssh
# или напрямую
ssh -l ubuntu <PUBLIC_IP>
```

Для проверки доступа из приватной ВМ через NAT:
```bash
ssh -J ubuntu@<PUBLIC_IP_OF_NAT> ubuntu@192.168.20.10
ping 8.8.8.8
```

<img width="717" height="362" alt="Снимок экрана 2025-11-03 191825" src="https://github.com/user-attachments/assets/8e4502c6-42fb-4668-af40-78d36d53c101" />

