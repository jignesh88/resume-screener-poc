import { useState, useEffect } from 'react'
import Head from 'next/head'
import { Typography, Container, Grid, CircularProgress, Box } from '@mui/material'
import { JobCard } from '@/components/JobCard'
import { JobFilter } from '@/components/JobFilter'
import { getJobs } from '@/services/api'
import { Job } from '@/types'

export default function Home() {
  const [jobs, setJobs] = useState<Job[]>([])
  const [filteredJobs, setFilteredJobs] = useState<Job[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null)

  useEffect(() => {
    const fetchJobs = async () => {
      try {
        setLoading(true)
        const data = await getJobs(selectedCategory)
        setJobs(data)
        setFilteredJobs(data)
        setError('')
      } catch (err) {
        console.error('Error fetching jobs:', err)
        setError('Failed to load jobs. Please try again later.')
      } finally {
        setLoading(false)
      }
    }

    fetchJobs()
  }, [selectedCategory])

  const handleFilterChange = (category: string | null) => {
    setSelectedCategory(category)
  }

  return (
    <>
      <Head>
        <title>Career Opportunities | Resume Screener</title>
        <meta name="description" content="Browse our latest job opportunities and apply online" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <main>
        <Container maxWidth="lg" className="py-8">
          <Typography variant="h3" component="h1" align="center" gutterBottom>
            Career Opportunities
          </Typography>
          <Typography variant="h6" component="h2" align="center" color="textSecondary" className="mb-8">
            Join our team and build your career with us
          </Typography>
          
          <JobFilter onFilterChange={handleFilterChange} selectedCategory={selectedCategory} />
          
          {loading ? (
            <Box display="flex" justifyContent="center" my={4}>
              <CircularProgress />
            </Box>
          ) : error ? (
            <Typography color="error" align="center" className="my-4">
              {error}
            </Typography>
          ) : filteredJobs.length === 0 ? (
            <Typography align="center" className="my-4">
              No jobs found. Please try a different filter or check back later.
            </Typography>
          ) : (
            <Grid container spacing={3} className="mt-2">
              {filteredJobs.map((job) => (
                <Grid item xs={12} sm={6} md={4} key={job.id}>
                  <JobCard job={job} />
                </Grid>
              ))}
            </Grid>
          )}
        </Container>
      </main>
    </>
  )
}
