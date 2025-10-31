# Web outputs
output "kubernetes_private_ips" {
  description = "Private IP addresses of Web VMs"
  value       = module.kubernetes.internal_ips
}

output "kubernetes_ssh" {
  description = "SSH commands to connect to Web VMs"
  value = [
    for ip in module.kubernetes.external_ips : "ssh -l ubuntu ${ip}"
  ]
}

output "kubernetes_node_private_ips" {
  description = "Private IP addresses of Web VMs"
  value       = module.kubernetes-nodes.internal_ips
}

output "kubernetes_node_ssh" {
  description = "SSH commands to connect to Web VMs"
  value = [
    for ip in module.kubernetes-nodes.external_ips : "ssh -l ubuntu ${ip}"
  ]
}
