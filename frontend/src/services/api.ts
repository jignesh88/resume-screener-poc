import axios from 'axios'
import { Job, ApplicationStatus } from '@/types'

// Get API URL from environment variables
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://your-api-gateway-url.execute-api.ap-southeast-2.amazonaws.com/prod'

// Create axios instance
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

/**
 * Get all jobs, optionally filtered by category
 */
export const getJobs = async (category: string | null = null): Promise<Job[]> => {
  try {
    const params = category ? { category } : {}
    const response = await api.get('/jobs', { params })
    return response.data.jobs || []
  } catch (error) {
    console.error('Error fetching jobs:', error)
    throw error
  }
}

/**
 * Get a specific job by ID
 */
export const getJob = async (jobId: string): Promise<Job> => {
  try {
    const response = await api.get(`/jobs/${jobId}`)
    return response.data.job
  } catch (error) {
    console.error(`Error fetching job ${jobId}:`, error)
    throw error
  }
}

/**
 * Submit a job application
 */
export const submitApplication = async (applicationData: any): Promise<{ applicationId: string; status: string }> => {
  try {
    const response = await api.post('/applications', applicationData)
    return response.data
  } catch (error) {
    console.error('Error submitting application:', error)
    throw error
  }
}

/**
 * Get application status
 */
export const getApplicationStatus = async (applicationId: string): Promise<ApplicationStatus> => {
  try {
    const response = await api.get(`/applications/${applicationId}`)
    return response.data
  } catch (error) {
    console.error(`Error fetching application status ${applicationId}:`, error)
    throw error
  }
}
