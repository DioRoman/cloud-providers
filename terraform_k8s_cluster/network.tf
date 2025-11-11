# Создание сетей, подсетей и групп безопасности

resource "yandex_vpc_network" "k8s_network" {
  name        = "k8s-ha-network"
  description = "Network for highly available Kubernetes cluster"
  
  # Флаг для автоматического создания подсетей (отключен для большей гибкости)
  depends_on = []
}

# Подсеть зоны ru-central1-a
resource "yandex_vpc_subnet" "k8s_subnet_a" {
  name            = "k8s-subnet-zone-a"
  description     = "Subnet in ru-central1-a zone"
  v4_cidr_blocks  = ["10.5.0.0/16"]
  zone            = "ru-central1-a"
  network_id      = yandex_vpc_network.k8s_network.id
  
  # Метки для облачного контроллера
  labels = {
    zone = "ru-central1-a"
    tier = "worker"
  }
}

# Подсеть зоны ru-central1-b
resource "yandex_vpc_subnet" "k8s_subnet_b" {
  name            = "k8s-subnet-zone-b"
  description     = "Subnet in ru-central1-b zone"
  v4_cidr_blocks  = ["10.6.0.0/16"]
  zone            = "ru-central1-b"
  network_id      = yandex_vpc_network.k8s_network.id
  
  labels = {
    zone = "ru-central1-b"
    tier = "worker"
  }
}

# Подсеть зоны ru-central1-d
resource "yandex_vpc_subnet" "k8s_subnet_d" {
  name            = "k8s-subnet-zone-d"
  description     = "Subnet in ru-central1-d zone"
  v4_cidr_blocks  = ["10.7.0.0/16"]
  zone            = "ru-central1-d"
  network_id      = yandex_vpc_network.k8s_network.id
  
  labels = {
    zone = "ru-central1-d"
    tier = "worker"
  }
}

resource "yandex_vpc_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes cluster"
  network_id  = yandex_vpc_network.k8s_network.id

  ingress {
    protocol           = "TCP"
    description        = "Load balancer health checks"
    predefined_target  = "loadbalancer_healthchecks"
    from_port          = 0
    to_port            = 65535
  }

  ingress {
    protocol           = "ANY"
    description        = "Master-node and node-node communication"
    predefined_target  = "self_security_group"
    from_port          = 0
    to_port            = 65535
  }

  ingress {
    protocol       = "ANY"
    description    = "Pod-pod and service-service communication"
    v4_cidr_blocks = flatten([
      yandex_vpc_subnet.k8s_subnet_a.v4_cidr_blocks,
      yandex_vpc_subnet.k8s_subnet_b.v4_cidr_blocks,
      yandex_vpc_subnet.k8s_subnet_d.v4_cidr_blocks
    ])
    from_port = 0
    to_port   = 65535
  }

  ingress {
    protocol       = "ICMP"
    description    = "Debug ICMP packets"
    v4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    description    = "NodePort range"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  egress {
    protocol       = "ANY"
    description    = "Allow outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

