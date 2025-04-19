import { Typography, Box, Chip, Divider, List, ListItem, ListItemText, ListItemIcon } from '@mui/material'
import { CalendarToday as CalendarIcon, LocationOn as LocationIcon, AttachMoney as SalaryIcon, WorkOutline as WorkIcon, CheckCircleOutline as CheckIcon } from '@mui/icons-material'
import { Job } from '@/types'

interface JobDetailsProps {
  job: Job
}

export function JobDetails({ job }: JobDetailsProps) {
  // Format the posted date
  const formattedDate = new Date(job.posted_date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })

  return (
    <div>
      <Box className="mb-4">
        <Typography variant="h4" component="h1" className="font-bold">
          {job.title}
        </Typography>
        
        <Box className="mt-2 flex flex-wrap gap-2 items-center">
          <Chip
            label={job.category}
            color="primary"
            variant="outlined"
            size="small"
          />
          <Typography variant="body2" color="textSecondary" className="flex items-center">
            <LocationIcon fontSize="small" className="mr-1" />
            {job.location}
          </Typography>
          <Typography variant="body2" color="textSecondary" className="flex items-center">
            <CalendarIcon fontSize="small" className="mr-1" />
            Posted: {formattedDate}
          </Typography>
        </Box>
      </Box>
      
      <Divider className="my-4" />
      
      <Box className="mb-6">
        <Typography variant="h6" component="h2" className="mb-3 font-medium">
          Job Overview
        </Typography>
        
        <Box className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <Box className="flex items-center">
            <LocationIcon className="text-primary-600 mr-2" />
            <Box>
              <Typography variant="body2" color="textSecondary">Location</Typography>
              <Typography variant="body1">{job.location}</Typography>
            </Box>
          </Box>
          
          <Box className="flex items-center">
            <WorkIcon className="text-primary-600 mr-2" />
            <Box>
              <Typography variant="body2" color="textSecondary">Job Type</Typography>
              <Typography variant="body1">{job.job_type || 'Full-time'}</Typography>
            </Box>
          </Box>
          
          <Box className="flex items-center">
            <SalaryIcon className="text-primary-600 mr-2" />
            <Box>
              <Typography variant="body2" color="textSecondary">Salary Range</Typography>
              <Typography variant="body1">{job.salary_range || 'Competitive'}</Typography>
            </Box>
          </Box>
          
          <Box className="flex items-center">
            <CalendarIcon className="text-primary-600 mr-2" />
            <Box>
              <Typography variant="body2" color="textSecondary">Closing Date</Typography>
              <Typography variant="body1">{job.closing_date || 'Open until filled'}</Typography>
            </Box>
          </Box>
        </Box>
      </Box>
      
      <Divider className="my-4" />
      
      <Box className="mb-6">
        <Typography variant="h6" component="h2" className="mb-3 font-medium">
          Job Description
        </Typography>
        
        <Typography variant="body1" component="div" className="whitespace-pre-line">
          {job.description}
        </Typography>
      </Box>
      
      {job.responsibilities && (
        <Box className="mb-6">
          <Typography variant="h6" component="h2" className="mb-3 font-medium">
            Responsibilities
          </Typography>
          
          <List>
            {job.responsibilities.map((item, index) => (
              <ListItem key={index} className="p-0 mb-2">
                <ListItemIcon className="min-w-0 mr-2">
                  <CheckIcon color="primary" fontSize="small" />
                </ListItemIcon>
                <ListItemText primary={item} />
              </ListItem>
            ))}
          </List>
        </Box>
      )}
      
      {job.requirements && (
        <Box className="mb-6">
          <Typography variant="h6" component="h2" className="mb-3 font-medium">
            Requirements
          </Typography>
          
          <List>
            {job.requirements.map((item, index) => (
              <ListItem key={index} className="p-0 mb-2">
                <ListItemIcon className="min-w-0 mr-2">
                  <CheckIcon color="primary" fontSize="small" />
                </ListItemIcon>
                <ListItemText primary={item} />
              </ListItem>
            ))}
          </List>
        </Box>
      )}
      
      {job.benefits && (
        <Box className="mb-6">
          <Typography variant="h6" component="h2" className="mb-3 font-medium">
            Benefits
          </Typography>
          
          <List>
            {job.benefits.map((item, index) => (
              <ListItem key={index} className="p-0 mb-2">
                <ListItemIcon className="min-w-0 mr-2">
                  <CheckIcon color="primary" fontSize="small" />
                </ListItemIcon>
                <ListItemText primary={item} />
              </ListItem>
            ))}
          </List>
        </Box>
      )}
    </div>
  )
}