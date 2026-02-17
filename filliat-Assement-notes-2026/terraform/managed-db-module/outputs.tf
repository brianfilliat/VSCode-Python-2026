output "cluster_id" {
  value = aws_rds_cluster.this.id
}

output "cluster_endpoint" {
  value = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.this.reader_endpoint
}

output "instance_ids" {
  value = aws_rds_cluster_instance.instances[*].id
}

output "secret_arn" {
  value = length(aws_secretsmanager_secret.this) > 0 ? aws_secretsmanager_secret.this[0].arn : null
}
