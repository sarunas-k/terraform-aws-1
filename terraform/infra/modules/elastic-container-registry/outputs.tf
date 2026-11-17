output "repository_url" {
  description = "URL of the ECR repository, without a tag"
  value       = module.ecr.repository_url
}
