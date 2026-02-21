output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.main.id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_id
}

output "db_cluster_endpoint" {
  description = "Primary DB cluster endpoint"
  value       = aws_rds_cluster.primary.endpoint
}

output "global_cluster_identifier" {
  description = "Global DB identifier"
  value       = aws_rds_global_cluster.global.global_cluster_identifier
}
