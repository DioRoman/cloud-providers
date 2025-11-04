resource "yandex_storage_bucket" "bucket" {
  bucket = var.bucket_name
  folder_id = var.folder_id

  anonymous_access_flags {
    read       = true   # публичное чтение объектов
    list       = true   # публичный просмотр содержимого бакета
  }

  default_storage_class = "STANDARD"
}

resource "yandex_storage_object" "image" {
  bucket       = yandex_storage_bucket.bucket.bucket
  key          = "image.jpg"          # имя файла в бакете
  source       = var.local_image_path
  content_type = "image/jpeg"
}