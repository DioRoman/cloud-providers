variable "vm_public" {
  type = list(
     object({ env_name = string, instance_name = string, instance_count = number, public_ip = bool, known_internal_ip = string, platform_id = string,
     cores = number, memory = number, disk_size = number, role= string }))
  default = ([ 
    { 
    env_name          = "vm-public",
    instance_name     = "vm-public", 
    instance_count    = 3, 
    public_ip         = true,
    known_internal_ip = "192.168.10.10",
    platform_id       = "standard-v3",
    cores             = 2,
    memory            = 4,
    disk_size         = 20,
    role              = "public"    
  }])
}

variable "vm_private" {
  type = list(
     object({ env_name = string, instance_name = string, instance_count = number, public_ip = bool, known_internal_ip = string, platform_id = string,
     cores = number, memory = number, disk_size = number, role= string }))
  default = ([ 
    { 
    env_name          = "vm-private",
    instance_name     = "vm-private", 
    instance_count    = 1, 
    public_ip         = false,
    known_internal_ip = "192.168.20.10",
    platform_id       = "standard-v3",
    cores             = 2,
    memory            = 4,
    disk_size         = 10,
    role              = "private"    
  }])
}

variable "vm_nat" {
  type = list(
     object({ env_name = string, instance_name = string, instance_count = number, public_ip = bool, known_internal_ip = string,  platform_id = string,
     cores = number, memory = number, disk_size = number, role= string }))
  default = ([ 
    { 
    env_name          = "vm-nat",
    instance_name     = "vm-nat", 
    instance_count    = 1, 
    public_ip         = true,
    known_internal_ip = "192.168.10.254",
    platform_id       = "standard-v3",
    cores             = 2,
    memory            = 4,
    disk_size         = 10,
    role              = "nat"    
  }])
}