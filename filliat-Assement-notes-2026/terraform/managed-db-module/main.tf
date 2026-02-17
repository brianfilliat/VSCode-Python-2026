// Managed Aurora RDS cluster module (example)

resource "aws_db_subnet_group" "this" {
  name       = coalesce(var.db_subnet_group_name, "${var.name_prefix}-db-subnets")
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-db-sg"
  description = "Security group for ${var.name_prefix} DB cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

// Optionally create a Secrets Manager secret if requested
resource "aws_secretsmanager_secret" "this" {
  count = var.create_secret ? 1 : 0
  name  = coalesce(var.secret_name, "${var.name_prefix}-db-secret")
  tags  = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  count      = var.create_secret ? 1 : 0
  secret_id  = aws_secretsmanager_secret.this[0].id
  secret_string = jsonencode({
    username = var.master_username
    password = var.master_password
  })
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = coalesce(var.db_cluster_identifier, "${var.name_prefix}-cluster")
  engine                  = var.engine
  engine_version          = var.engine_version
  database_name           = var.database_name
  master_username         = var.master_username
  master_password         = var.master_password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = concat(var.security_group_ids, [aws_security_group.this.id])
  backup_retention_period = var.backup_retention_days
  apply_immediately       = var.apply_immediately
  skip_final_snapshot     = var.skip_final_snapshot
  tags                    = var.tags

  depends_on = [aws_db_subnet_group.this]
}

resource "aws_rds_cluster_instance" "instances" {
  count              = var.instance_count
  identifier         = "${var.name_prefix}-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = var.engine
  engine_version     = var.engine_version
  publicly_accessible = var.publicly_accessible
  tags               = var.tags
}
