output "bucket_id" {
  description = "Name of the bucket the website files are uploaded to"
  value       = aws_s3_bucket.this.id
}

output "distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cdn.cloudfront_distribution_domain_name
}

output "distribution_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = module.cdn.cloudfront_distribution_hosted_zone_id
}
