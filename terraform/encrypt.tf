resource "yandex_kms_symmetric_key" "bucket_key" {
  name               = "bucket-encryption-key"
  description        = "Key for encrypting object storage bucket"
  default_algorithm  = "AES_256"
  rotation_period    = "168h" # ротация ключа каждую неделю
  deletion_protection = false # только для обучения

  # lifecycle {
  #   prevent_destroy = true # защитить ключ от случайного удаления
  # }
}
