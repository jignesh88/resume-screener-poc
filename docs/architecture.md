# AWS Phone-Based Chatbot Architecture

## Architecture Diagram

```mermaid
flowchart TD
    subgraph S3["Amazon S3"]
        S3_bucket["Resume Bucket"]
    end

    subgraph Lambda["AWS Lambda"]
        extract["Extract Text"]        
        screen["Screen Resume"]
        rank["Rank Candidates"]
        phone["Phone Interview"]
        schedule["Schedule Interview"]
    end

    subgraph StepFunctions["AWS Step Functions"]
        workflow["Resume Screening Workflow"]        
    end

    subgraph DynamoDB
        candidates["Candidate Table"]
    end

    subgraph OpenSearch["Amazon OpenSearch"]
        vectors["Vector Embeddings"]
    end

    subgraph Bedrock["Amazon Bedrock"]
        model["Claude 3 Sonnet"]
        kb["Knowledge Base"]
    end

    subgraph Connect["Amazon Connect"]
        flow["Contact Flow"]
        phone_num["Phone Number"]
    end

    subgraph SES["Amazon SES"]
        email["Email Service"]
    end

    subgraph Textract["Amazon Textract"]
        ocr["Text Extraction"]
    end

    subgraph CloudWatch["Amazon CloudWatch"]
        logs["Logs"]
        metrics["Metrics"]
        alarms["Alarms"]
    end

    User --> S3_bucket
    S3_bucket --> workflow
    workflow --> extract
    workflow --> screen
    workflow --> rank
    workflow --> phone
    workflow --> schedule
    
    extract --> ocr
    ocr --> extract
    extract --> candidates
    
    screen --> model
    model --> screen
    screen --> kb
    kb --> screen
    kb --> vectors
    screen --> candidates
    
    rank --> candidates
    candidates --> rank
    
    phone --> model
    model --> phone
    phone --> flow
    flow --> phone_num
    phone_num --> Candidate["Candidate"]
    phone --> candidates
    
    schedule --> email
    email --> HiringManager["Hiring Manager"]
    email --> TechStaff["Technical Staff"]
    email --> Candidate
    schedule --> candidates
    
    Lambda --> logs
    StepFunctions --> logs
    metrics --> alarms

    classDef aws fill:#FF9900,stroke:#232F3E,color:white;
    classDef externalEntity fill:#91C0F1,stroke:#0A67A3,color:white;
    classDef data fill:#48A3C6,stroke:#0A67A3,color:white;
    
    class S3,Lambda,StepFunctions,DynamoDB,OpenSearch,Bedrock,Connect,SES,Textract,CloudWatch aws;
    class Candidate,HiringManager,TechStaff,User externalEntity;
    class S3_bucket,candidates,vectors,logs,metrics,alarms data;
```

## Component Descriptions

### Storage and Data Components

- **Amazon S3**: Stores resume documents and call recordings
  - Resume Bucket: Central repository for all candidate resumes

- **Amazon DynamoDB**: NoSQL database for candidate tracking
  - Candidate Table: Stores candidate information, screening results, rankings, and interview status

- **Amazon OpenSearch**: Vector database for RAG capabilities
  - Vector Embeddings: Stores embeddings for semantic search of resumes

### Processing Components

- **AWS Lambda**: Serverless compute for various processing steps
  - Extract Text: Processes uploaded resumes using Textract
  - Screen Resume: Evaluates resumes against job requirements
  - Rank Candidates: Compares candidates and identifies top performers
  - Phone Interview: Manages phone call interactions
  - Schedule Interview: Handles interview scheduling logic

- **AWS Step Functions**: Orchestrates the end-to-end workflow
  - Resume Screening Workflow: Coordinates all steps with error handling

- **Amazon Textract**: OCR and document processing service
  - Text Extraction: Extracts structured data from resumes

### AI and Communication Components

- **Amazon Bedrock**: Foundation model service for AI capabilities
  - Claude 3 Sonnet: LLM for analyzing resumes and generating responses
  - Knowledge Base: RAG system for enhanced context understanding

- **Amazon Connect**: Cloud contact center service
  - Contact Flow: Define the customer interaction flow
  - Phone Number: Toll-free number for outbound calls

- **Amazon SES**: Email service for notifications
  - Email Service: Sends interview invitations and confirmations

### Monitoring and Logging

- **Amazon CloudWatch**: Monitoring and observability service
  - Logs: Centralized logging for all components
  - Metrics: Custom and service-level metrics
  - Alarms: Automated notifications for errors and thresholds

### External Entities

- **User**: HR or recruiting staff uploading resumes
- **Candidate**: Job applicant being screened and interviewed
- **Hiring Manager**: Department manager conducting interviews
- **Technical Staff**: Team members participating in technical interviews

## Data Flow

1. Resumes are uploaded to S3 by recruiting staff
2. Step Functions workflow is triggered by S3 event
3. Extract Text Lambda uses Textract to process resume documents
4. Screen Resume Lambda evaluates candidates using Bedrock
5. Rank Candidates Lambda identifies top candidates
6. Phone Interview Lambda conducts automated screening calls via Connect
7. Schedule Interview Lambda arranges interviews via email
8. All components log to CloudWatch for monitoring and troubleshooting

## Security Considerations

- All data at rest is encrypted
- IAM roles follow principle of least privilege
- Network traffic is encrypted in transit
- OpenSearch domain uses fine-grained access control
- S3 bucket blocks public access
- Lambda functions operate in secure VPC (recommended for production)