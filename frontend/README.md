# Resume Screener Frontend

A Next.js application for the job application portal that allows candidates to browse job listings, view job details, submit applications with resume uploads, and check application status.

## Features

### Job Listings
- Browse all available job positions
- Filter jobs by category (Engineering, Data Science, etc.)
- View job details including requirements and responsibilities

### Job Application
- User-friendly application form
- Resume upload with drag-and-drop functionality
- Support for PDF, DOC, and DOCX formats
- Application tracking and status checking

## Technology Stack

- **Framework**: Next.js 13 with TypeScript
- **UI Components**: Material UI (MUI)
- **Styling**: Tailwind CSS with MUI integration
- **Form Handling**: React Hook Form
- **File Upload**: React Dropzone
- **HTTP Client**: Axios
- **Build Output**: Static export for S3 hosting

## Project Structure

```
/frontend
├── public/                # Static assets
├── src/
│   ├── components/        # Reusable React components
│   │   ├── ApplicationForm.tsx   # Job application form with file upload
│   │   ├── JobCard.tsx           # Job listing card component
│   │   ├── JobDetails.tsx        # Detailed job information display
│   │   ├── JobFilter.tsx         # Job category filtering
│   │   └── Layout.tsx            # Application layout with header/footer
│   ├── pages/            # Next.js pages
│   │   ├── _app.tsx             # Application wrapper with theme
│   │   ├── _document.tsx        # HTML document customization
│   │   ├── index.tsx            # Home page with job listings
│   │   ├── jobs/[id].tsx        # Dynamic job details page
│   │   └── application-status/[id].tsx  # Application status page
│   ├── services/         # API service functions
│   │   └── api.ts               # Backend API integration
│   ├── styles/           # Global styles
│   │   └── globals.css          # Tailwind imports and global CSS
│   └── types/            # TypeScript type definitions
│       └── index.ts             # Shared type definitions
├── next.config.js        # Next.js configuration
├── package.json          # Project dependencies
├── tailwind.config.js    # Tailwind CSS configuration
└── tsconfig.json         # TypeScript configuration
```

## Getting Started

### Prerequisites

- Node.js 16.x or higher
- npm or yarn package manager

### Development

1. Install dependencies:
   ```bash
   npm install
   # or
   yarn install
   ```

2. Create a `.env.local` file with the API endpoint:
   ```
   NEXT_PUBLIC_API_URL=https://your-api-gateway-url.execute-api.ap-southeast-2.amazonaws.com/prod
   ```

3. Start the development server:
   ```bash
   npm run dev
   # or
   yarn dev
   ```

4. Open [http://localhost:3000](http://localhost:3000) in your browser.

### Building for Production

```bash
# Build and export static files
npm run build

# The output will be in the 'out' directory
```

## Deployment

The application is designed to be deployed as a static site on AWS S3 with CloudFront distribution. Deployment is handled by the `deploy_frontend.sh` script in the root of the repository, which:

1. Builds the Next.js application with production environment variables
2. Syncs the output files to the S3 bucket
3. Invalidates the CloudFront cache

To deploy manually:

```bash
# From the repository root
./deploy_frontend.sh
```

## Testing

Component-level testing can be implemented using Jest and React Testing Library. To add tests, create a `__tests__` directory within the components or pages directories.

## Adding New Features

### Adding a New Page

Create a new file in the `src/pages` directory. Next.js will automatically create a route based on the file name.

### Adding a New Component

Create a new component in the `src/components` directory and import it where needed.

### Adding New API Endpoints

Update the `src/services/api.ts` file with new functions for any additional API endpoints.

## Contributing

1. Create a new branch for your feature
2. Make changes and test locally
3. Submit a pull request with a detailed description of your changes

## License

MIT
