--Create S3 Extention
CREATE EXTENSION IF NOT EXISTS aws_s3 CASCADE;

--Create Schemas for each department
CREATE SCHEMA finance_schema;
CREATE SCHEMA administration_schema;


--Create function for Export to Finance S3 Bucket
CREATE OR REPLACE FUNCTION finance_schema.export_to_finance_bucket(IN sql_query TEXT
                                                  , IN bucket_key TEXT
                                                  , OUT rows_uploaded BIGINT
                                                  , OUT files_uploaded BIGINT
                                                  , OUT bytes_uploaded BIGINT)
  SECURITY DEFINER
  SET search_path = pg_catalog,pg_temp
AS
$$
BEGIN
    EXECUTE 'SELECT * from aws_s3.query_export_to_s3(''' || sql_query || ''', aws_commons.create_s3_uri(''tf-djl-finance-bucket'',''' || bucket_key || ''', ''us-east-1''));'
        INTO rows_uploaded, files_uploaded, bytes_uploaded;
END;
$$  LANGUAGE plpgsql;



--Create function for Export to Adminstration S3 Bucket
CREATE OR REPLACE FUNCTION administration_schema.export_to_administration_bucket(IN sql_query TEXT
                                                         , IN bucket_key TEXT
                                                         , OUT rows_uploaded BIGINT
                                                         , OUT files_uploaded BIGINT
                                                         , OUT bytes_uploaded BIGINT)
  SECURITY DEFINER
  SET search_path = pg_catalog,pg_temp
AS
$$
BEGIN
    EXECUTE 'SELECT * from aws_s3.query_export_to_s3(''' || sql_query || ''', aws_commons.create_s3_uri(''tf-djl-administration-bucket'',''' || bucket_key || ''', ''us-east-1''));'
        INTO rows_uploaded, files_uploaded, bytes_uploaded;
END;
$$  LANGUAGE plpgsql;


--Create users
CREATE USER finance_user WITH PASSWORD 'password';
CREATE USER admin_user   WITH PASSWORD 'password';

--Grant usage to corresponding users
GRANT USAGE ON SCHEMA finance_schema TO finance_user; 
GRANT USAGE ON SCHEMA administration_schema TO admin_user;

--Create Sample data to export.
CREATE TABLE public.sample_table (bid bigint PRIMARY KEY, name varchar(80));
INSERT INTO public.sample_table (bid,name) VALUES (1, 'Monday'), (2,'Tuesday'), (3, 'Wednesday');