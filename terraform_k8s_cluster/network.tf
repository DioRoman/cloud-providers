module "yandex-vpc" {
  source              = "git::https://github.com/DioRoman/ter-yandex-vpc-module.git?ref=a7c4bbb"
  env_name            = "k8s-ha-network"
  network_description = "Network for highly available Kubernetes cluster"
  subnets             = var.subnets
  security_groups = [
    {
      name        = "k8s-security-group"
      description = "Security group for Kubernetes cluster"
      ingress_rules = [
        {
          protocol    = "TCP"
          from_port   = 0
          to_port     = 65535
          description = "Node-node and pod-pod communication"
          cidr_blocks = concat([var.cluster_ipv4_range, var.service_ipv4_range], [for subnet in var.subnets : subnet.cidr], ["91.204.150.0/24"])
        },
        {
          protocol    = "TCP"
          from_port   = 80
          to_port     = 80
          description = "HTTP access for phpMyAdmin"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          from_port   = 6443
          to_port     = 6443
          description = "Kubernetes API access"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          from_port   = 3306
          to_port     = 3306
          description = "MySQL access"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          from_port   = 10256
          to_port     = 10256
          description = "Kubernetes API access"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          from_port   = 443
          to_port     = 443
          description = "Kubernetes API access"
          cidr_blocks = ["0.0.0.0/0"]
        },
        {
          protocol    = "TCP"
          from_port   = 22
          to_port     = 22
          description = "SSH access"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ],
      egress_rules = [
        {
          protocol    = "ANY"
          from_port   = 0
          to_port     = 65535
          description = "Allow outbound traffic"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
  ]
}
