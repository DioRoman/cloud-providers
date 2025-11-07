###cloud vars
variable "cloud_id" {
  type        = string
  default     = "b1g2uh898q9ekgq43tfq"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  default     = "b1g22qi1cc8rq4avqgik"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

###vpc vars

variable "vpc_default_zone" {
  description = "Available default subnets."
  type        = list(string)
  default     = [
    "ru-central1-a",
    "ru-central1-b",
    "ru-central1-d",
  ]
}

variable "vpc_default_cidr" {
  description = "Available cidr blocks for public subnets."
  type        = list(string)
  default     = [
    "192.168.10.0/24",
    "192.168.20.0/24",
    "192.168.30.0/24",
  ]
}

###vm vars

variable "vm_web_image_family" {
  type        = string
  default     = "ubuntu-2404-lts"
}

variable "vm_ssh_root_key" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "ssh-keygen -t ed25519"
}

variable "vm_nat_image" {
  type        = string
  default     = "fd8hqm1si8i5ul8v396c"
}

variable "vm_lamp_image" {
  type        = string
  default     = "fd8na0csfs8r1mb91trm"
}


variable "bucket_name" {
  type        = string
  default     = "dio-new-bucket-20251105"
  description = "Unique bucket name"
}

variable "local_image_path" {
  type        = string
  default     = "/mnt/c/Users/rlyst/GIT/cloud-providers/terraform/image.jpg"
  description = "Local path to the image file to upload"
}

variable "service_account_id" {
  description = "Service account ID for VM instance group"
  type        = string
  default     = "ajegmcrosjf3g105qpsd"
}

variable "nlb_external_ip" {
  description = "External IP for NLB"
  type        = string
  default     = null
}
