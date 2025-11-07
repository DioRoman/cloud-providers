# Web outputs
# output "vm_public_ips" {
#   description = "Private IP addresses of Web VMs"
#   value       = module.vm_public.internal_ips
# }

output "vm_nat_ips" {
  description = "Private IP addresses of Web VMs"
  value       = module.vm_nat.internal_ips
}

output "vm_private_ips" {
  description = "Private IP addresses of Web VMs"
  value       = module.vm_private.internal_ips
}


# output "vm_public_ssh" {
#   description = "SSH commands to connect to Web VMs"
#   value = [
#     for ip in module.vm_public.external_ips : "ssh -l ubuntu ${ip}"
#   ]
# }

output "bucket_name" {
  value       = yandex_storage_bucket.bucket.bucket
  description = "Name of the created bucket"
}

output "image_object_url" {
  value       = "https://storage.yandexcloud.net/${yandex_storage_bucket.bucket.bucket}/image.jpg"
  description = "Public URL to access the uploaded image"
}

output "nlb_ip" {
  description = "External IP address of the network load balancer"
  value = yandex_vpc_address.nlb_external_ip.external_ipv4_address[0].address
}


output "vm_public_group_external_ips" {
  description = "External IP addresses of instances in public VM group"
  value = [
    for instance in yandex_compute_instance_group.vm_public_group.instances : "http://${instance.network_interface[0].nat_ip_address}"
  ]
}
