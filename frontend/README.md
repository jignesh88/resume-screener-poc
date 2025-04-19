# Resume Screener Frontend

This is a React application for the job application portal that allows candidates to:

1. Browse available job listings
2. View job details
3. Submit applications with resume uploads
4. Check application status

## Setup and Installation

### Prerequisites

- Node.js 16+ installed
- npm or yarn package manager

### Installation

```bash
# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build
```

## Configuration

The application uses environment variables for configuration. Create a `.env` file in the root directory with the following variables:

```
REACT_APP_API_URL=<API_Gateway_URL>
REACT_APP_REGION=ap-southeast-2
```

For production, make sure to set these environment variables in your hosting environment.

## Project Structure

```
/frontend
├── public/                 # Static files
├── src/
│   ├── components/         # React components
│   ├── pages/              # Page components
│   ├── hooks/              # Custom React hooks
│   ├── utils/              # Utility functions
│   ├── services/           # API service functions
│   ├── context/            # React context providers
│   ├── styles/             # CSS/SCSS styles
│   ├── App.js              # Main app component
│   └── index.js            # Entry point
├── package.json            # Project dependencies and scripts
└── README.md               # Project documentation
```

## Features

### Job Listings

The home page displays all available job listings from DynamoDB. Users can:

- View all job listings
- Filter by job category or title
- Sort by posting date or other criteria

### Job Details

Users can view detailed information about each job:

- Full job description
- Requirements and qualifications
- Company information
- Application deadline

### Application Submission

The application process includes:

- Application form with personal information
- Resume upload to S3
- Additional questions specific to the job

### Application Status

Users can check the status of their submitted applications:

- Application received
- Resume screening in progress
- Phone interview scheduled
- Interview scheduled
- Application result

## Deployment

The frontend can be deployed to AWS Amplify, S3 with CloudFront, or any other static website hosting service.

### AWS Amplify Deployment

```bash
# Install AWS Amplify CLI
npm install -g @aws-amplify/cli

# Initialize Amplify
amplify init

# Add hosting
amplify add hosting

# Deploy
amplify publish
```

### S3 and CloudFront Deployment

Build the React app and upload the build folder to an S3 bucket configured for static website hosting. Then create a CloudFront distribution pointing to the S3 bucket.

## Connecting to Backend

The frontend connects to the backend API Gateway endpoint for all data operations. The API URL should be configured in the environment variables.
