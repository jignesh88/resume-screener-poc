import { useState } from 'react'
import { useRouter } from 'next/router'
import { useForm, Controller } from 'react-hook-form'
import { TextField, Button, Grid, Typography, Box, Alert, CircularProgress, InputAdornment } from '@mui/material'
import { DescriptionOutlined as FileIcon, Person as PersonIcon, Email as EmailIcon, Phone as PhoneIcon, LinkedIn as LinkedInIcon } from '@mui/icons-material'
import { useDropzone } from 'react-dropzone'
import { submitApplication } from '@/services/api'

interface ApplicationFormProps {
  jobId: string
}

interface FormData {
  fullName: string
  email: string
  phone: string
  linkedIn?: string
  portfolio?: string
  coverLetter?: string
  additionalInfo?: string
}

export function ApplicationForm({ jobId }: ApplicationFormProps) {
  const router = useRouter()
  const [resumeFile, setResumeFile] = useState<File | null>(null)
  const [uploading, setUploading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)
  
  const { control, handleSubmit, formState: { errors } } = useForm<FormData>({
    defaultValues: {
      fullName: '',
      email: '',
      phone: '',
      linkedIn: '',
      portfolio: '',
      coverLetter: '',
      additionalInfo: ''
    }
  })
  
  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    accept: {
      'application/pdf': ['.pdf'],
      'application/msword': ['.doc'],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx']
    },
    maxFiles: 1,
    maxSize: 5 * 1024 * 1024, // 5MB max size
    onDrop: (acceptedFiles) => {
      if (acceptedFiles.length > 0) {
        setResumeFile(acceptedFiles[0])
        setError('')
      }
    },
    onDropRejected: (rejectedFiles) => {
      if (rejectedFiles.length > 0) {
        const { errors } = rejectedFiles[0]
        if (errors.some(e => e.code === 'file-too-large')) {
          setError('File is too large. Maximum size is 5MB.')
        } else if (errors.some(e => e.code === 'file-invalid-type')) {
          setError('Invalid file type. Please upload a PDF, DOC, or DOCX file.')
        } else {
          setError('Error uploading file. Please try again.')
        }
      }
    }
  })
  
  const onSubmit = async (data: FormData) => {
    if (!resumeFile) {
      setError('Please upload your resume')
      return
    }
    
    setUploading(true)
    setError('')
    
    try {
      // Convert resume file to base64
      const resumeBase64 = await convertFileToBase64(resumeFile)
      
      // Submit the application
      const applicationData = {
        ...data,
        jobId,
        resume: resumeBase64
      }
      
      const response = await submitApplication(applicationData)
      setSuccess(true)
      
      // Redirect to application status page after a brief delay
      setTimeout(() => {
        router.push(`/application-status/${response.applicationId}`)
      }, 2000)
    } catch (err) {
      console.error('Error submitting application:', err)
      setError('Failed to submit application. Please try again.')
    } finally {
      setUploading(false)
    }
  }
  
  const convertFileToBase64 = (file: File): Promise<string> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.readAsDataURL(file)
      reader.onload = () => resolve(reader.result as string)
      reader.onerror = error => reject(error)
    })
  }
  
  if (success) {
    return (
      <Box className="py-8 text-center">
        <Alert severity="success" className="mb-4">
          Your application has been submitted successfully!
        </Alert>
        <Typography variant="body1" className="mb-4">
          Redirecting to your application status page...
        </Typography>
        <CircularProgress size={24} />
      </Box>
    )
  }
  
  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <Grid container spacing={3}>
        {/* Personal Information */}
        <Grid item xs={12}>
          <Typography variant="h6" className="mb-2">Personal Information</Typography>
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Controller
            name="fullName"
            control={control}
            rules={{ required: 'Full name is required' }}
            render={({ field }) => (
              <TextField
                {...field}
                label="Full Name"
                variant="outlined"
                fullWidth
                error={!!errors.fullName}
                helperText={errors.fullName?.message}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <PersonIcon />
                    </InputAdornment>
                  ),
                }}
              />
            )}
          />
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Controller
            name="email"
            control={control}
            rules={{ 
              required: 'Email is required',
              pattern: {
                value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                message: 'Invalid email address'
              }
            }}
            render={({ field }) => (
              <TextField
                {...field}
                label="Email"
                variant="outlined"
                fullWidth
                error={!!errors.email}
                helperText={errors.email?.message}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <EmailIcon />
                    </InputAdornment>
                  ),
                }}
              />
            )}
          />
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Controller
            name="phone"
            control={control}
            rules={{ 
              required: 'Phone number is required',
              pattern: {
                value: /^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/,
                message: 'Invalid phone number'
              }
            }}
            render={({ field }) => (
              <TextField
                {...field}
                label="Phone Number"
                variant="outlined"
                fullWidth
                error={!!errors.phone}
                helperText={errors.phone?.message}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <PhoneIcon />
                    </InputAdornment>
                  ),
                }}
              />
            )}
          />
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Controller
            name="linkedIn"
            control={control}
            render={({ field }) => (
              <TextField
                {...field}
                label="LinkedIn Profile (Optional)"
                variant="outlined"
                fullWidth
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <LinkedInIcon />
                    </InputAdornment>
                  ),
                }}
              />
            )}
          />
        </Grid>
        
        <Grid item xs={12}>
          <Controller
            name="portfolio"
            control={control}
            render={({ field }) => (
              <TextField
                {...field}
                label="Portfolio URL (Optional)"
                variant="outlined"
                fullWidth
              />
            )}
          />
        </Grid>
        
        {/* Resume Upload */}
        <Grid item xs={12} className="mt-4">
          <Typography variant="h6" className="mb-2">Resume</Typography>
          
          <Box
            {...getRootProps()}
            className={`p-6 border-2 border-dashed rounded-md text-center cursor-pointer transition-colors ${isDragActive ? 'border-primary-500 bg-primary-50' : 'border-gray-300 hover:border-primary-400'}`}
          >
            <input {...getInputProps()} />
            <FileIcon fontSize="large" className="text-secondary-400 mb-2" />
            
            {resumeFile ? (
              <>
                <Typography variant="body1" className="mb-1 font-medium text-primary-700">
                  {resumeFile.name}
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  {(resumeFile.size / 1024 / 1024).toFixed(2)} MB
                </Typography>
                <Button
                  size="small"
                  className="mt-2"
                  onClick={(e) => {
                    e.stopPropagation()
                    setResumeFile(null)
                  }}
                >
                  Remove
                </Button>
              </>
            ) : (
              <>
                <Typography variant="body1" className="mb-1">
                  Drag & drop your resume here, or click to select file
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Supported formats: PDF, DOC, DOCX (Max 5MB)
                </Typography>
              </>
            )}
          </Box>
          
          {error && (
            <Alert severity="error" className="mt-2">
              {error}
            </Alert>
          )}
        </Grid>
        
        {/* Additional Information */}
        <Grid item xs={12} className="mt-4">
          <Typography variant="h6" className="mb-2">Additional Information (Optional)</Typography>
        </Grid>
        
        <Grid item xs={12}>
          <Controller
            name="coverLetter"
            control={control}
            render={({ field }) => (
              <TextField
                {...field}
                label="Cover Letter"
                variant="outlined"
                fullWidth
                multiline
                rows={4}
                placeholder="Introduce yourself and explain why you're a good fit for this position"
              />
            )}
          />
        </Grid>
        
        <Grid item xs={12}>
          <Controller
            name="additionalInfo"
            control={control}
            render={({ field }) => (
              <TextField
                {...field}
                label="Additional Information"
                variant="outlined"
                fullWidth
                multiline
                rows={3}
                placeholder="Any other information you'd like to share"
              />
            )}
          />
        </Grid>
        
        {/* Submit Button */}
        <Grid item xs={12} className="mt-4">
          <Button
            type="submit"
            variant="contained"
            color="primary"
            size="large"
            disabled={uploading}
            className="min-w-[200px]"
          >
            {uploading ? (
              <>
                <CircularProgress size={24} color="inherit" className="mr-2" />
                Submitting...
              </>
            ) : 'Submit Application'}
          </Button>
        </Grid>
      </Grid>
    </form>
  )
}
