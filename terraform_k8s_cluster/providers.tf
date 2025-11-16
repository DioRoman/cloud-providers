terraform {
  backend "s3" {
    shared_credentials_files = ["~/.aws/credentials"]
    shared_config_files      = ["~/.aws/config"]
    profile                  = "default"
    region                   = "ru-central1"
    bucket                   = "dio-bucket"
    key                      = "terraform-learning/terraform.tfstate"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    endpoints = {
      dynamodb = "https://docapi.serverless.yandexcloud.net/ru-central1/b1g2uh898q9ekgq43tfq/etns1jscufdghn2f5san"
      s3       = "https://storage.yandexcloud.net"
    }
    dynamodb_table = "dio-bucket-lock-01"
  }

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.85.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">=2"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11.0"
    }
  }
  required_version = ">=1.8"
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.vpc_default_zone[2]
  service_account_key_file = file("~/.authorized_key.json")
}

provider "kubernetes" {
  host                   = yandex_kubernetes_cluster.k8s_cluster.master[0].external_v4_endpoint
  cluster_ca_certificate = yandex_kubernetes_cluster.k8s_cluster.master[0].cluster_ca_certificate
  token                  = data.yandex_client_config.client.iam_token
}

data "yandex_client_config" "client" {}
