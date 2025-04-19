# Project Structure

```
/resume-screener-poc
├── main.tf                 # Main Terraform configuration file
├── variables.tf            # Input variables for the Terraform project
├── outputs.tf              # Output values from the Terraform project
├── example.tfvars          # Example variable values (create terraform.tfvars for actual deployment)
├── lambda/
│   ├── extract_text/       # Lambda function for extracting text from resumes
│   │   └── extract_text.py
│   ├── screen_resume/      # Lambda function for screening resumes with Bedrock
│   │   └── screen_resume.py
│   ├── rank_candidates/    # Lambda function for ranking candidates
│   │   └── rank_candidates.py
│   ├── phone_interview/    # Lambda function for conducting phone interviews
│   │   └── phone_interview.py
│   └── schedule_interview/ # Lambda function for scheduling interviews via email
│       └── schedule_interview.py
├── .gitignore              # Git ignore file
└── README.md               # Project documentation and setup instructions
```

## Key Components

1. **Terraform Configuration**:
   - `main.tf`: Defines all AWS resources including S3, Lambda, DynamoDB, OpenSearch, IAM roles, and Step Functions
   - `variables.tf`: Declares all configurable input parameters
   - `outputs.tf`: Defines useful output values like ARNs and endpoints

2. **Lambda Functions**:
   - `extract_text.py`: Uses Textract to extract text from resume documents
   - `screen_resume.py`: Uses Bedrock to evaluate candidate resumes against job requirements
   - `rank_candidates.py`: Ranks candidates and identifies top performers
   - `phone_interview.py`: Manages Amazon Connect phone interviews
   - `schedule_interview.py`: Handles email scheduling with hiring managers

3. **Step Functions Workflow**:
   - Orchestrates the end-to-end candidate screening and interview process
   - Conditionally advances candidates based on performance

4. **Documentation**:
   - `README.md`: Comprehensive setup and usage instructions
   - `PROJECT_STRUCTURE.md`: This file, explaining the project organization