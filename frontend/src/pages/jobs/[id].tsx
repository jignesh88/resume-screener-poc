import { useState, useEffect } from 'react'
import { useRouter } from 'next/router'
import Head from 'next/head'
import { Button, Typography, Container, Paper, Box, Divider, Chip, CircularProgress } from '@mui/material'
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material'
import { JobDetails } from '@/components/JobDetails'
import { ApplicationForm } from '@/components/ApplicationForm'
import { getJob } from '@/services/api'
import { Job } from '@/types'

export default function JobPage() {
  const router = useRouter()
  const { id } = router.query
  
  const [job, setJob] = useState<Job | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [showApplicationForm, setShowApplicationForm] = useState(false)

  useEffect(() => {
    if (!id) return

    const fetchJob = async () => {
      try {
        setLoading(true)
        const data = await getJob(id as string)
        setJob(data)
        setError('')
      } catch (err) {
        console.error('Error fetching job:', err)
        setError('Failed to load job details. Please try again later.')
      } finally {
        setLoading(false)
      }
    }

    fetchJob()
  }, [id])

  const handleApply = () => {
    setShowApplicationForm(true)
    // Scroll to application form
    setTimeout(() => {
      document.getElementById('application-form')?.scrollIntoView({ behavior: 'smooth' })
    }, 100)
  }

  const handleBack = () => {
    router.push('/')
  }

  return (
    <>
      <Head>
        <title>{job ? `${job.title} | Resume Screener` : 'Job Details | Resume Screener'}</title>
        <meta name="description" content={job ? `Apply for ${job.title} position at our company` : 'Job details'} />
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

          {loading ? (
            <Box display="flex" justifyContent="center" my={4}>
              <CircularProgress />
            </Box>
          ) : error ? (
            <Typography color="error" align="center" className="my-4">
              {error}
            </Typography>
          ) : job ? (
            <>
              <Paper elevation={2} className="p-6 mb-8">
                <JobDetails job={job} />
                
                {!showApplicationForm && (
                  <Box display="flex" justifyContent="center" className="mt-8">
                    <Button
                      variant="contained"
                      color="primary"
                      size="large"
                      onClick={handleApply}
                    >
                      Apply Now
                    </Button>
                  </Box>
                )}
              </Paper>

              {showApplicationForm && (
                <Paper elevation={2} className="p-6" id="application-form">
                  <Typography variant="h5" component="h2" gutterBottom>
                    Apply for {job.title}
                  </Typography>
                  <Divider className="mb-4" />
                  <ApplicationForm jobId={job.id} />
                </Paper>
              )}
            </>
          ) : (
            <Typography align="center" className="my-4">
              Job not found.
            </Typography>
          )}
        </Container>
      </main>
    </>
  )
}
