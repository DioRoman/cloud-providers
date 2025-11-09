terraform {

  backend "s3" {
      
      shared_credentials_files = ["~/.aws/credentials"]
      shared_config_files = [ "~/.aws/config" ]
      profile = "default"
      region="ru-central1"

      bucket     = "dio-bucket"
      key = "terraform-learning/terraform.tfstate"

      skip_region_validation      = true
      skip_credentials_validation = true
      skip_requesting_account_id  = true # Необходимая опция Terraform для версии 1.6.1 и старше.
      skip_s3_checksum            = true # Необходимая опция при описании бэкенда для Terraform версии 1.6.3 и старше.

    endpoints ={
      dynamodb = "https://docapi.serverless.yandexcloud.net/ru-central1/b1g2uh898q9ekgq43tfq/etns1jscufdghn2f5san"
      s3 = "https://storage.yandexcloud.net"
    }

    dynamodb_table              = "dio-bucket-lock-01"
  }

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
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
  }
  required_version = ">=1.8"
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.vpc_default_zone[2]
  service_account_key_file = file("~/.authorized_key.json")
}