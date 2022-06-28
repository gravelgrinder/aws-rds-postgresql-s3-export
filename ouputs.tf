### RDS Endpoint
output "rds_endpoint" { value = aws_db_instance.pgrds.endpoint}

### S3 Bucket Names
output "bucket_names" { value = aws_s3_bucket.bucket[*].bucket }