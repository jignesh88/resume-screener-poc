# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Frontend: `cd frontend && npm run dev` - Start development server
- Frontend: `cd frontend && npm run build` - Build for production
- Frontend: `cd frontend && npm run lint` - Run ESLint
- Frontend: `cd frontend && npm run export` - Build and export static files
- Infrastructure: `terraform init && terraform apply -var-file=terraform.tfvars`
- Deploy frontend: `./deploy_frontend.sh`
- Test Lambda: `python -m lambda.[function_dir].[function_file]`

## Code Style Guidelines
- **TypeScript**: Use TypeScript for all frontend code (strict mode off)
- **Components**: Functional React components with hooks-based state management
- **Naming**: PascalCase for components/interfaces, camelCase for functions/variables
- **Imports**: React/Next.js first, third-party libs second, local imports last
- **Error Handling**: Try/catch for API calls, form validation via react-hook-form
- **Styling**: Tailwind CSS with custom theme in tailwind.config.js
- **Types**: Define interfaces in src/types/index.ts
- **API**: Centralize HTTP requests in services/api.ts using Axios
- **File Structure**: Follow Next.js conventions (pages/, components/, services/)
- **Lambda Functions**: Python 3.9+ with requirements.txt for dependencies