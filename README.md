# aws-rds-postgresql-s3-export
Repo to demonstrate the RDS PostgreSQL S3 export feature.

## Architecture
![alt text](https://github.com/gravelgrinder/aws-rds-postgresql-s3-export/blob/main/images/architecture-diagram.png?raw=true)

## Prerequisite

## Setup Steps
1. Run the following to Initialize the Terraform environment.

```
terraform init
```

2. Provision the resources in the Terraform scripts

```
terraform apply
```
3. Connect to PostgreSQL RDS Instance as the admin account (foo).  Use the `rds_endpoint` value from the Terraform output.  Password is in the `01-db.tf` script.
4. Run the `sql/pg_script.sql` script against the PostgreSQL database.  Run as the admin user.  This script will create the necessary components which include.
  * Creation of the aws_s3 Extention.
  * Creation of 2 new schemas (one for each department)
  * Creation of 2 custom export functions (one for each department)
  * Creation of 2 new users (one for each department)
  * Necessary grants per user
  * Creation of sample data used for S3 export.
5. Log in as "Finance" user, attempt to export to s3 buckets. Use the folliwng query.
```
SELECT * from finance_schema.export_to_finance_bucket('select * from public.sample_table', 
	                                                    'my-file-01.csv');
```

6. Log in as "Administration" user, attempt to export to s3 buckets. Use the following query.
```                           
SELECT * from administration_schema.export_to_administration_bucket('select * from public.sample_table', 
      	                                                       'my-file-01.csv');
```

7. Verify the __**inability**__ for each user to be able to use the other custom functions. For example the `finance_user` should not be able to call the function residing in the `administration_schema` to export to the Administration Bucket.

8. Verify the __**inability**__ for each user to be able to use the`aws_s3.query_export_to_s3()` function directly.
```
SELECT * from aws_s3.query_export_to_s3(
	'select * from public.sample_table', 
	'tf-djl-finance-bucket', 
	'my-file-02.csv', 
	'us-east-1', 
	'');
```


Helpful Links
* [RDS User Guide - Exporting data from an RDS for PostgreSQL DB instance to Amazon S3](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/postgresql-s3-export.html)
* [AWS Blog: Export and import data from Amazon S3 to Amazon Aurora PostgreSQL](https://aws.amazon.com/blogs/database/export-and-import-data-from-amazon-s3-to-amazon-aurora-postgresql/)



## Questions & Comments
If you have any questions or comments on the demo please reach out to me [Devin Lewis - AWS Solutions Architect](mailto:lwdvin@amazon.com?subject=AWS%20RDS%20PostgreSQL%20S3%20Export%20Securing%20Function%20Demo%20%28aws-rds-postgresql-s3-export%29)

Of if you would like to provide personal feedback to me please click [Here](https://feedback.aws.amazon.com/?ea=lwdvin&fn=Devin&ln=Lewis)
