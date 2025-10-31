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
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
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