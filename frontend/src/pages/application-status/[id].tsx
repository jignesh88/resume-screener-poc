import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import Head from 'next/head'
import { Typography, Container, Paper, Box, Stepper, Step, StepLabel, CircularProgress, Button } from '@mui/material'
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material'
import { getApplicationStatus } from '@/services/api'
import { ApplicationStatus } from '@/types'

const steps = ['Application Submitted', 'Resume Screening', 'Phone Interview', 'Interview Scheduled']

export default function ApplicationStatusPage() {
  const router = useRouter()
  const { id } = router.query
  
  const [applicationStatus, setApplicationStatus] = useState<ApplicationStatus | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [activeStep, setActiveStep] = useState(0)

  useEffect(() => {
    if (!id) return

    const fetchStatus = async () => {
      try {
        setLoading(true)
        const data = await getApplicationStatus(id as string)
        setApplicationStatus(data)
        setError('')
        
        // Set the active step based on the status
        switch (data.status) {
          case 'SUBMITTED':
            setActiveStep(0)
            break
          case 'EXTRACTED':
          case 'SCREENED':
          case 'RANKED':
            setActiveStep(1)
            break
          case 'PHONE_INTERVIEW_INITIATED':
          case 'PHONE_INTERVIEW_COMPLETED':
            setActiveStep(2)
            break
          case 'INTERVIEW_SCHEDULED':
            setActiveStep(3)
            break
          default:
            setActiveStep(0)
        }
      } catch (err) {
        console.error('Error fetching application status:', err)
        setError('Failed to load application status. Please try again later.')
      } finally {
        setLoading(false)
      }
    }

    fetchStatus()
    
    // Poll for status updates every 30 seconds
    const intervalId = setInterval(() => {
      fetchStatus()
    }, 30000)
    
    return () => clearInterval(intervalId)
  }, [id])

  const handleBack = () => {
    router.push('/')
  }

  const getStatusMessage = () => {
    if (!applicationStatus) return ''
    
    switch (applicationStatus.status) {
      case 'SUBMITTED':
        return 'Your application has been received. We will begin processing it shortly.'
      case 'EXTRACTED':
        return 'We are currently reviewing your resume.'
      case 'SCREENED':
        return 'Your resume has been screened and is being evaluated.'
      case 'RANKED':
        return 'Your application has been ranked among other candidates.'
      case 'PHONE_INTERVIEW_INITIATED':
        return 'We are preparing to conduct a phone interview. Please expect a call soon.'
      case 'PHONE_INTERVIEW_COMPLETED':
        return 'Your phone interview has been completed. We are evaluating your responses.'
      case 'INTERVIEW_SCHEDULED':
        return 'Congratulations! You have been selected for an interview.'
      default:
        return 'Your application is being processed.'
    }
  }

  return (
    <>
      <Head>
        <title>Application Status | Resume Screener</title>
        <meta name="description" content="Check the status of your job application" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main>
        <Container maxWidth="md" className="py-8">
          <Button
            startIcon={<ArrowBackIcon />}
            onClick={handleBack}
            className="mb-4"
          >
            Back to Jobs
          </Button>

          <Typography variant="h4" component="h1" align="center" gutterBottom>
            Application Status
          </Typography>

          {loading ? (
            <Box display="flex" justifyContent="center" my={4}>
              <CircularProgress />
            </Box>
          ) : error ? (
            <Typography color="error" align="center" className="my-4">
              {error}
            </Typography>
          ) : applicationStatus ? (
            <Paper elevation={2} className="p-6">
              <Box className="mb-6">
                <Typography variant="subtitle1" color="textSecondary" gutterBottom>
                  Application ID:
                </Typography>
                <Typography variant="body1">
                  {applicationStatus.applicationId}
                </Typography>
              </Box>
              
              <Box className="mb-6">
                <Typography variant="subtitle1" color="textSecondary" gutterBottom>
                  Submission Date:
                </Typography>
                <Typography variant="body1">
                  {new Date(applicationStatus.submissionDate).toLocaleString()}
                </Typography>
              </Box>
              
              <Box className="mb-8">
                <Typography variant="subtitle1" color="textSecondary" gutterBottom>
                  Current Status:
                </Typography>
                <Typography variant="body1" color="primary" fontWeight="medium">
                  {getStatusMessage()}
                </Typography>
              </Box>
              
              <Stepper activeStep={activeStep} alternativeLabel>
                {steps.map((label) => (
                  <Step key={label}>
                    <StepLabel>{label}</StepLabel>
                  </Step>
                ))}
              </Stepper>
            </Paper>
          ) : (
            <Typography align="center" className="my-4">
              Application not found.
            </Typography>
          )}
        </Container>
      </main>
    </>
  )
}
