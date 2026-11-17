variable "bucket_name" {
  description = "Name of the S3 bucket that stores the website files"
  type        = string
}

variable "domain_name" {
  description = "Domain the website is served on"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for domain_name"
  type        = string
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "cache_policy_name" {
  description = "Name of the CloudFront cache policy for the default behavior"
  type        = string
  default     = "Managed-CachingOptimized"
}

variable "content_dir" {
  description = "Local directory whose files are uploaded to the bucket"
  type        = string
}
