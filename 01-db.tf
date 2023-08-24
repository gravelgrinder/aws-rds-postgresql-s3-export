### Consumer Account Resources
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}



###############################################################################
### djl-pgsql-db-1
###############################################################################
resource "aws_security_group" "db_sg" {
  name        = "tf_db_postgresql_sg"
  description = "Database Security Group created by Terraform for a PostgreSQL RDS DB"
  vpc_id      = "vpc-00b09e53c6e62a994"

  tags = {
    Name = "tf_db_postgresql_sg"
  }
}

resource "aws_security_group_rule" "allow_ingress_from_vpc" {
  type              = "ingress"
  description       = "Allow inbound connections from the VPC."
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.db_sg.id
}


resource "aws_security_group_rule" "allow_egress" {
  type              = "egress"
  description       = "Allow all outbound connections"
  from_port         = -1
  to_port           = -1
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db_sg.id
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "tf_db_group"
  subnet_ids = ["subnet-069a69e50bd1ebb23", "subnet-0871b35cbe9d0c1cf", "subnet-045bd90a8091ea930"]
}

resource "aws_db_instance" "pgrds" {
  depends_on           = [aws_security_group.db_sg]
  allocated_storage    = 10
  storage_encrypted    = true
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t3.micro"
  publicly_accessible  = false
  identifier           = "djl-pgsql-db-1"
  db_name              = "djl"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "djl-postgres13-pg"
  iam_database_authentication_enabled = "true"
  apply_immediately                   = "true"
  vpc_security_group_ids              = [aws_security_group.db_sg.id]
  db_subnet_group_name                = aws_db_subnet_group.db_subnet_group.id
  multi_az                            = false
  #backup_retention_period             = 35
  skip_final_snapshot                 = true
  tags = {Name = "djl-pgsql-db-1", phidb = true, s3export = true, storagetier = "s3glacier"}
  copy_tags_to_snapshot = true
}
###############################################################################





###############################################################################
### Create S3 Buckets
###############################################################################
resource "aws_s3_bucket" "bucket" {
  count  = length(var.departments)
  bucket = join("", ["tf-djl-", lower(var.departments[count.index]), "-bucket"])
  force_destroy = true

  tags = {
      Name        = "${var.departments[count.index]} Department Bucket"
      Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "bucket" {
  count = length(var.departments)
  bucket = aws_s3_bucket.bucket[count.index].id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "bucket" {
  count = length(var.departments)
  bucket = aws_s3_bucket.bucket[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  count = length(var.departments)
  bucket = aws_s3_bucket.bucket[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  count = length(var.departments)
  bucket = aws_s3_bucket.bucket[count.index].id

  rule {
    id      = "expire_version"
    filter {
      prefix = ""
    }
    expiration {days = 1}
    noncurrent_version_expiration {noncurrent_days = 1}
    abort_incomplete_multipart_upload { days_after_initiation = 1 }
    status = "Enabled"
  }

  

  rule {
    id      = "delete_version"
    filter {
      prefix = ""
    }
    expiration {expired_object_delete_marker = true}
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  count = length(var.departments)
  bucket = aws_s3_bucket.bucket[count.index].id

  block_public_acls   = true
  ignore_public_acls  = true
  block_public_policy = true
  restrict_public_buckets = true
}
###############################################################################



###############################################################################
### IAM Role for RDS Instance to allow S3 Export functionality
###############################################################################
## Create IAM Policy for connecting to DB 
data "template_file" "rds_s3_export_policy" {
  template = "${file("iam/rds_s3_export_policy.json")}"

  vars = { s3_buckets = join("\",\"", [for bucket in aws_s3_bucket.bucket : "${bucket.arn}/*"])  }
}

data "template_file" "assume_role_policy" {
  template = "${file("iam/assume_role_policy.json")}"

  vars = { rds_resource_arn = "${aws_db_instance.pgrds.arn}"}
}

resource "aws_iam_policy" "rds_s3_export" {
  name        = "tf_rds_s3_export_policy"
  description = "IAM Policy to allow the RDS PostgeSQL database to export to the Finance and Administration S3 Buckets."
  policy      = "${data.template_file.rds_s3_export_policy.rendered}"
}

resource "aws_iam_role" "rds_s3_export" {
  name                = "tf_rds_s3_export_role"
  assume_role_policy  = "${data.template_file.assume_role_policy.rendered}"
  managed_policy_arns = [aws_iam_policy.rds_s3_export.arn]
}
###############################################################################





###############################################################################
### Associate IAM Role with PostgreSQL RDS Instance
###############################################################################
resource "aws_db_instance_role_association" "pgrds" {
  db_instance_identifier = aws_db_instance.pgrds.id
  feature_name           = "s3Export"
  role_arn               = aws_iam_role.rds_s3_export.arn
}
###############################################################################