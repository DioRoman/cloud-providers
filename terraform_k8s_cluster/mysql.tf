resource "kubernetes_secret" "mysql-password" {
  metadata {
    name = "mysql-password"
  }
  data = {
    password = base64encode(var.mysql_password)
  }
}

resource "kubernetes_pod" "mysql" {
  metadata {
    name = "mysql"
    labels = {
      app = "mysql"
    }
  }
  spec {
    container {
      name  = "mysql"
      image = var.mysql_image
      env {
        name  = "MYSQL_ROOT_PASSWORD"
        value = var.mysql_password
      }
      env {
        name  = "MYSQL_DATABASE"
        value = "db-test"
      }
      env {
        name  = "MYSQL_USER"
        value = "db-user"
      }
      env {
        name  = "MYSQL_PASSWORD"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.mysql-password.metadata[0].name
            key  = "password"
          }
        }
      }
      port {
        container_port = 3306
      }
      resources {
        limits = {
          cpu    = var.mysql_resources.cpu
          memory = var.mysql_resources.memory
        }
        requests = {
          cpu    = var.mysql_resources.cpu_req
          memory = var.mysql_resources.mem_req
        }
      }
      volume_mount {
        name       = "mysql-storage"
        mount_path = "/var/lib/mysql"
      }
    }
    volume {
      name = "mysql-storage"
      empty_dir {}
    }
  }
}

resource "kubernetes_service" "mysql" {
  metadata {
    name = "mysql"
  }
  spec {
    selector = {
      app = "mysql"
    }
    port {
      port        = 3306
      target_port = 3306
    }
    type = "ClusterIP"
  }
}
