output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "repository_url" {
  description = "URL of the ECR repository, without a tag"
  value       = module.ecr.repository_url
}
