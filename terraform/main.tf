# Создание сетей, подсетей и групп безопасности

module "yandex-vpc" {
  source       = "git::https://github.com/DioRoman/ter-final.git//src/modules/yandex-vpc?ref=main"
  env_name     = var.kubernetes[0].env_name
  subnets = [
    { zone = var.vpc_default_zone[0], cidr = var.vpc_default_cidr[1] }
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
        {
          protocol    = "TCP"
          port        = 10443
          description = "MicroK8s console"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          port        = 30080
          description = "MicroK8s service"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          port        = 30880
          description = "MicroK8s service"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          port        = 8080
          description = "MicroK8s service"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          port        = 6443
          description = "	Kubernetes API server"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          port        = 10250
          description = "Kubelet API"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          port        = 10259
          description = "kube-scheduler"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          port        = 10257
          description = "kube-controller-manager"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          from_port = 2379
          to_port   = 2380   
          description = "etcd server client API"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          port        = 10256
          description = "kube-proxy"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          from_port = 30000
          to_port   = 32767
          description = "NodePort Services"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "UDP"
          from_port = 30000
          to_port   = 32767
          description = "NodePort Services"
          cidr_blocks = ["0.0.0.0/0"]
        }
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

# Создание VM

module "kubernetes" {
  source              = "git::https://github.com/DioRoman/ter-final.git//src/modules/yandex-vm?ref=main"
  vm_name             = var.kubernetes[0].instance_name 
  vm_count            = var.kubernetes[0].instance_count
  zone                = var.vpc_default_zone[0]
  subnet_ids          = module.yandex-vpc.subnet_ids
  image_id            = data.yandex_compute_image.ubuntu.id
  platform_id         = var.kubernetes[0].platform_id
  cores               = var.kubernetes[0].cores
  memory              = var.kubernetes[0].memory
  disk_size           = var.kubernetes[0].disk_size 
  public_ip           = var.kubernetes[0].public_ip
  security_group_ids  = [module.yandex-vpc.security_group_ids["web"]]
  
  labels = {
    env  = var.kubernetes[0].env_name
    role = var.kubernetes[0].role
  }

  metadata = {
    user-data = data.template_file.kubernetes.rendered
    serial-port-enable = local.serial-port-enable
  }  
}

module "kubernetes-nodes" {
  source              = "git::https://github.com/DioRoman/ter-final.git//src/modules/yandex-vm?ref=main"
  vm_name             = var.kubernetes-node[0].instance_name 
  vm_count            = var.kubernetes-node[0].instance_count
  zone                = var.vpc_default_zone[0]
  subnet_ids          = module.yandex-vpc.subnet_ids
  image_id            = data.yandex_compute_image.ubuntu.id
  platform_id         = var.kubernetes-node[0].platform_id
  cores               = var.kubernetes-node[0].cores
  memory              = var.kubernetes-node[0].memory
  disk_size           = var.kubernetes-node[0].disk_size 
  public_ip           = var.kubernetes-node[0].public_ip
  security_group_ids  = [module.yandex-vpc.security_group_ids["web"]]
  
  labels = {
    env  = var.kubernetes-node[0].env_name
    role = var.kubernetes-node[0].role
  }

  metadata = {
    user-data = data.template_file.kubernetes.rendered
    serial-port-enable = local.serial-port-enable
  }  
}

# Инициализация 
data "template_file" "kubernetes" {
  template = file("./kubernetes.yml")
    vars = {
    ssh_public_key     = file(var.vm_ssh_root_key)
  }
}

# Получение id образа Ubuntu
data "yandex_compute_image" "ubuntu" {
  family = var.vm_web_image_family
}
