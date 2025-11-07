resource "yandex_storage_bucket" "bucket" {
  bucket    = var.bucket_name
  folder_id = var.folder_id

  anonymous_access_flags {
    read = true
    list = true
  }

  default_storage_class = "STANDARD"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_object" "image" {
  bucket       = yandex_storage_bucket.bucket.bucket
  key          = "image.jpg"
  source       = var.local_image_path
  content_type = "image/jpeg"
}