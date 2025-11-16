resource "kubernetes_deployment" "phpmyadmin" {
  metadata {
    name = "phpmyadmin"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "phpmyadmin"
      }
    }
    template {
      metadata {
        labels = {
          app = "phpmyadmin"
        }
      }
      spec {
        container {
          name  = "phpmyadmin"
          image = var.phpmyadmin_image
          env {
            name  = "PMA_HOST"
            value = "mysql"
          }
          env {
            name  = "PMA_PORT"
            value = "3306"
          }
          env {
            name  = "PMA_USER"
            value = "db-user"
          }
          env {
            name  = "PMA_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql-password.metadata[0].name
                key  = "password"
              }
            }
          }
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "phpmyadmin-service" {
  metadata {
    name = "phpmyadmin-service"
  }
  spec {
    selector = {
      app = "phpmyadmin"
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
