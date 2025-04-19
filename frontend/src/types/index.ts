export interface Job {
  id: string
  title: string
  company?: string
  category: string
  location: string
  job_type?: string
  salary_range?: string
  description: string
  short_description: string
  responsibilities?: string[]
  requirements?: string[]
  benefits?: string[]
  posted_date: string
  closing_date?: string
  status?: string
}

export interface ApplicationStatus {
  applicationId: string
  jobId: string
  status: string
  submissionDate: string
  updatedDate: string
}

export interface ApplicationFormData {
  jobId: string
  fullName: string
  email: string
  phone: string
  resume: string
  linkedIn?: string
  portfolio?: string
  coverLetter?: string
  additionalInfo?: string
}
