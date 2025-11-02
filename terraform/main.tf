# Создание сетей, подсетей и групп безопасности

module "yandex-vpc" { 
  source       = "git::https://github.com/DioRoman/ter-yandex-vpc-module.git?ref=main"
  env_name     = var.vm_public[0].env_name
  subnets = [
    {
      name        = "public"
      cidr        = "192.168.10.0/24"
      zone        = "ru-central1-a"
      description = "Public subnet"
    },
    {
      name        = "private"
      cidr        = "192.168.20.0/24"
      zone        = "ru-central1-a"
      description = "Private subnet"
      route_table_id = yandex_vpc_route_table.private.id
    }
  ]
  
  security_groups = [
    {
      name        = "web"
      description = "Security group for web servers"
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

# Добавление статического маршрута для исходящего трафика из приватной подсети через NAT-инстанс
resource "yandex_vpc_route_table" "private" {
  name       = "private-route-table"
  network_id = module.yandex-vpc.network_id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
  labels = {
    environment = "dev"
  }
}

# Создание VM

module "vm_public" {
  source              = "git::https://github.com/DioRoman/ter-yandex-vm-module.git?ref=main"
  vm_name             = var.vm_public[0].instance_name 
  vm_count            = var.vm_public[0].instance_count
  zone                = var.vpc_default_zone[0]
  subnet_ids          = [module.yandex-vpc.subnet_ids[0]]
  image_id            = data.yandex_compute_image.ubuntu.id
  platform_id         = var.vm_public[0].platform_id
  cores               = var.vm_public[0].cores
  memory              = var.vm_public[0].memory
  disk_size           = var.vm_public[0].disk_size 
  public_ip           = var.vm_public[0].public_ip
  security_group_ids  = [module.yandex-vpc.security_group_ids["web"]]
  
  labels = {
    env  = var.vm_public[0].env_name
    role = var.vm_public[0].role
  }

  metadata = {
    user-data = data.template_file.vm.rendered
    serial-port-enable = local.serial-port-enable
  }  
}

module "vm_private" {
  source              = "git::https://github.com/DioRoman/ter-yandex-vm-module.git?ref=main"
  vm_name             = var.vm_private[0].instance_name 
  vm_count            = var.vm_private[0].instance_count
  zone                = var.vpc_default_zone[0]
  subnet_ids          = [module.yandex-vpc.subnet_ids[1]]
  image_id            = data.yandex_compute_image.ubuntu.id
  platform_id         = var.vm_private[0].platform_id
  cores               = var.vm_private[0].cores
  memory              = var.vm_private[0].memory
  disk_size           = var.vm_private[0].disk_size 
  public_ip           = var.vm_private[0].public_ip
  security_group_ids  = [module.yandex-vpc.security_group_ids["web"]]
  
  labels = {
    env  = var.vm_private[0].env_name
    role = var.vm_private[0].role
  }

  metadata = {
    user-data = data.template_file.vm.rendered
    serial-port-enable = local.serial-port-enable
  }  
}

module "vm_nat" {
  source              = "git::https://github.com/DioRoman/ter-yandex-vm-module.git?ref=main"
  vm_name             = var.vm_nat[0].instance_name 
  vm_count            = var.vm_nat[0].instance_count
  zone                = var.vpc_default_zone[0]
  subnet_ids          = [module.yandex-vpc.subnet_ids[0]]
  image_id            = var.vm_nat_image
  platform_id         = var.vm_nat[0].platform_id
  cores               = var.vm_nat[0].cores
  memory              = var.vm_nat[0].memory
  disk_size           = var.vm_nat[0].disk_size 
  public_ip           = var.vm_nat[0].public_ip
  known_internal_ip   = var.vm_nat[0].known_internal_ip
  security_group_ids  = [module.yandex-vpc.security_group_ids["web"]]
  
  labels = {
    env  = var.vm_nat[0].env_name
    role = var.vm_nat[0].role
  }

  metadata = {
    user-data = data.template_file.vm.rendered
    serial-port-enable = local.serial-port-enable
  }  
}

# Инициализация 
data "template_file" "vm" {
  template = file("./vm.yml")
    vars = {
    ssh_public_key     = file(var.vm_ssh_root_key)
  }
}

# Получение id образа Ubuntu
data "yandex_compute_image" "ubuntu" {
  family = var.vm_web_image_family
}
