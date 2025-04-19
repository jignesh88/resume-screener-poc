# Terraform configuration for deploying the Next.js frontend to S3 and CloudFront

#------------------------------------------------------------
# S3 Bucket for Static Website Hosting
#------------------------------------------------------------
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = var.frontend_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
        # Remove the circular dependency with CloudFront
        # Condition = {
        #   StringEquals = {
        #     "AWS:SourceArn" = aws_cloudfront_distribution.frontend_distribution.arn
        #   }
        # }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "frontend_bucket_block" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "frontend_bucket_versioning" {
  bucket = aws_s3_bucket.frontend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "frontend_bucket_ownership" {
  bucket = aws_s3_bucket.frontend_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

#------------------------------------------------------------
# CloudFront Origin Access Control
#------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "${var.frontend_bucket_name}-oac"
  description                       = "OAC for frontend website bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

#------------------------------------------------------------
# CloudFront Distribution
#------------------------------------------------------------
resource "aws_cloudfront_distribution" "frontend_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # US, Canada, Europe
  http_version        = "http2and3"
  
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.frontend_bucket.bucket
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
  }
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.frontend_bucket.bucket
    compress         = true
    
    cache_policy_id          = aws_cloudfront_cache_policy.frontend_cache_policy.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.frontend_origin_request_policy.id
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  # Handle SPA routing - return index.html for all paths that don't match a file
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
  
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
  
  tags = {
    Name = "Resume Screener Frontend"
  }
  
  # Dependencies managed separately to avoid circular references
}

#------------------------------------------------------------
# CloudFront Cache Policy
#------------------------------------------------------------
resource "aws_cloudfront_cache_policy" "frontend_cache_policy" {
  name        = "${var.frontend_bucket_name}-cache-policy"
  min_ttl     = 1
  max_ttl     = 31536000 # 1 year
  default_ttl = 86400     # 1 day
  
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    
    headers_config {
      header_behavior = "none"
    }
    
    query_strings_config {
      query_string_behavior = "none"
    }
    
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

#------------------------------------------------------------
# CloudFront Origin Request Policy
#------------------------------------------------------------
resource "aws_cloudfront_origin_request_policy" "frontend_origin_request_policy" {
  name = "${var.frontend_bucket_name}-origin-request-policy"
  
  cookies_config {
    cookie_behavior = "none"
  }
  
  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
    }
  }
  
  query_strings_config {
    query_string_behavior = "none"
  }
}

#------------------------------------------------------------
# Output: CloudFront Distribution Domain Name
#------------------------------------------------------------
output "frontend_cloudfront_domain" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend_distribution.domain_name
}

output "frontend_cloudfront_dist_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend_distribution.id
}

output "frontend_bucket_name" {
  description = "The name of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend_bucket.bucket
}
