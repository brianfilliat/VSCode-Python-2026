# Terraform template for an S3 bucket with versioning and logging enabled

# 1. Create the S3 bucket for logs (Destination)
resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-tf-log-bucket-unique-id" # Change to a unique name
}

# 2. Set ownership and ACL for the log bucket
resource "aws_s3_bucket_ownership_controls" "log_bucket_oc" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket_oc]

  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

# 3. Create the main S3 bucket (Source)
resource "aws_s3_bucket" "main_bucket" {
  bucket = "my-tf-main-bucket-unique-id" # Change to a unique name
}

# 4. Enable Versioning on the main bucket
resource "aws_s3_bucket_versioning" "main_bucket_versioning" {
  bucket = aws_s3_bucket.main_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 5. Enable Logging on the main bucket
resource "aws_s3_bucket_logging" "main_bucket_logging" {
  bucket = aws_s3_bucket.main_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# 6. Best Practice: Enable Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main_bucket_sse" {
  bucket = aws_s3_bucket.main_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 7. Best Practice: Block Public Access
resource "aws_s3_bucket_public_access_block" "main_bucket_pab" {
  bucket = aws_s3_bucket.main_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
