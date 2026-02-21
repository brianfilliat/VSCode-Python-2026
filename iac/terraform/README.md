# Terraform starter scaffold

This folder contains a minimal Terraform scaffold to provision a VPC, an EKS cluster (via community module), an Aurora (Postgres) cluster, and a stub for an Aurora Global DB (cross-region replica).

What this includes
- `main.tf` - providers, VPC, subnets, EKS module usage, Aurora primary cluster, global cluster stub
- `variables.tf` - variables you should set (region, AZs, DB credentials)
- `outputs.tf` - useful outputs

Quick start
1. Install Terraform (>= 1.4)
2. Configure AWS credentials (env or named profile)

```bash
export AWS_PROFILE=your-profile
cd iac/terraform
terraform init
terraform plan -var 'db_master_password=CHANGEME' -out plan.tfplan
terraform apply plan.tfplan
```

Notes & next steps
- Fill `db_master_password` via variable or a secure secrets backend (Sops/Secrets Manager)
- The `aws_rds_global_cluster` + secondary `aws_rds_cluster` usage requires the proper IAM permissions and may need running from each region or using aliased providers as shown.
- The EKS module reference requires `terraform init` to pull the community module; adjust `node_groups` to match real sizing.
- This is a starter scaffold — add IAM, KMS keys, monitoring, logging, and tighter network/NACLs before production.
