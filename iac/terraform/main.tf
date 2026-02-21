terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.prefix}-vpc" }
}

resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = true
  tags = { Name = "${var.prefix}-public-${element(var.azs, count.index)}" }
}

resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  availability_zone = element(var.azs, count.index)
  tags = { Name = "${var.prefix}-private-${element(var.azs, count.index)}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.prefix}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_db_subnet_group" "db_subnet" {
  name       = "${var.prefix}-db-subnet"
  subnet_ids = aws_subnet.private[*].id
  tags = { Name = "${var.prefix}-db-subnet" }
}

resource "aws_security_group" "eks_cluster" {
  name   = "${var.prefix}-eks-sg"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = [var.admin_cidr] }
  egress  { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "db_sg" {
  name   = "${var.prefix}-db-sg"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 5432; to_port = 5432; protocol = "tcp"; security_groups = [aws_security_group.eks_cluster.id] }
  egress  { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

# --- EKS (module-based starter) ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnets         = aws_subnet.private[*].id
  vpc_id          = aws_vpc.main.id

  node_groups = {
    default = {
      desired_capacity = var.eks_node_count
      instance_types   = var.eks_node_instance_types
    }
  }
}

# --- Aurora Primary cluster ---
resource "aws_rds_cluster" "primary" {
  cluster_identifier      = var.db_cluster_identifier
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  master_username         = var.db_master_username
  master_password         = var.db_master_password
  skip_final_snapshot     = true
  backup_retention_period = var.db_backup_retention
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
}

resource "aws_rds_cluster_instance" "primary_instances" {
  count              = var.db_instance_count
  identifier         = "${var.db_cluster_identifier}-inst-${count.index}"
  cluster_identifier = aws_rds_cluster.primary.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.primary.engine
}

# --- Global cluster (cross-region) ---
resource "aws_rds_global_cluster" "global" {
  global_cluster_identifier = var.global_cluster_identifier
  engine                    = var.db_engine
}

# Secondary/replica cluster in another region (created using aliased provider)
resource "aws_rds_cluster" "secondary" {
  provider                = aws.secondary
  cluster_identifier      = "${var.db_cluster_identifier}-secondary"
  engine                  = var.db_engine
  engine_version          = var.db_engine_version
  master_username         = var.db_master_username
  master_password         = var.db_master_password
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  global_cluster_identifier = aws_rds_global_cluster.global.global_cluster_identifier
}

output "vpc_id" { value = aws_vpc.main.id }
output "eks_cluster_name" { value = module.eks.cluster_id }
output "db_cluster_endpoint" { value = aws_rds_cluster.primary.endpoint }
output "global_cluster_identifier" { value = aws_rds_global_cluster.global.global_cluster_identifier }
