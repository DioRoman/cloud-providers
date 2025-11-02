# Web outputs
output "vm_public_ips" {
  description = "Private IP addresses of Web VMs"
  value       = module.vm_public.internal_ips
}

output "vm_nat_ips" {
  description = "Private IP addresses of Web VMs"
  value       = module.vm_nat.internal_ips
}

output "vm_private_ips" {
  description = "Private IP addresses of Web VMs"
  value       = module.vm_private.internal_ips
}


output "vm_public_ssh" {
  description = "SSH commands to connect to Web VMs"
  value = [
    for ip in module.vm_public.external_ips : "ssh -l ubuntu ${ip}"
  ]
}
