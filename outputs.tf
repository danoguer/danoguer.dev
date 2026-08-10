output "cloudfront_url" {
  description = "CloudFront HTTPS domain URL"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "s3_bucket_name" {
  description = "Name of the provisioned S3 Bucket"
  value       = aws_s3_bucket.mybucket.id
}
