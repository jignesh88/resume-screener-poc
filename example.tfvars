# Example Terraform variables
# DO NOT include sensitive information in this file
# Create a separate terraform.tfvars file for your actual deployment

aws_region = "ap-southeast-2"
resume_bucket_name = "candidate-resumes-example"
opensearch_domain_name = "resume-search-example"

# WARNING: These are example values only, do not use in production
opensearch_master_user = "admin"
opensearch_master_password = "CHANGEME_StrongPasswordRequired123!"

dynamodb_table_name = "candidate-tracking-example"

# These must be manually created in Amazon Connect
connect_instance_id = "your-connect-instance-id"
connect_contact_flow_id = "your-connect-flow-id"

# ARN of the Secrets Manager secret containing Gmail API credentials
gmail_credentials_secret_arn = "arn:aws:secretsmanager:ap-southeast-2:123456789012:secret:example-gmail-credentials"

# Contact emails
hiring_manager_email = "hiring_manager@example.com"
technical_staff_email = "tech_staff@example.com"
company_name = "Example Corp"
company_phone = "+61291234567"
