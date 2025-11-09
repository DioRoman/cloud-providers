output "cluster_id" {
  description = "MySQL cluster ID"
  value       = yandex_mdb_mysql_cluster.netology_mysql_cluster.id
}

output "cluster_name" {
  description = "MySQL cluster name"
  value       = yandex_mdb_mysql_cluster.netology_mysql_cluster.name
}

output "database_name" {
  description = "Database name"
  value       = yandex_mdb_mysql_database.netology_db.name
}

output "mysql_user" {
  description = "MySQL username"
  value       = yandex_mdb_mysql_user.netology_user.name
}

output "mysql_hosts" {
  description = "MySQL hosts information"
  value = [
    for host in yandex_mdb_mysql_cluster.netology_mysql_cluster.host : {
      fqdn = host.fqdn
      zone = host.zone
    }
  ]
}

output "mysql_password_secret_id" {
  description = "Lockbox secret ID for MySQL password"
  value       = yandex_lockbox_secret.mysql_password.id
  sensitive   = true
}

