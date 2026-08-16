output "cloudfront_url" {
  description = "CloudFront HTTPS domain URL"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "s3_bucket_name" {
  description = "Name of the provisioned S3 Bucket"
  value       = aws_s3_bucket.mybucket.id
}

output "route53_nameservers" {
  description = "4 nameservers"
  value       = aws_route53_zone.main.name_servers
}
