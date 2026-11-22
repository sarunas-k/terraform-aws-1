variable "aws_region" {
  description = "AWS Region for the provider"
  type        = string
}

variable "environment" {
  description = "Environment name, applied as the Environment tag on all resources"
  type        = string
}

variable "dns_zone_name" {
  description = "Domain of the DNS zone"
  type        = string
}

variable "dns_record_name" {
  description = "Subdomain of the DNS record"
  type        = string
}

variable "failover_site_bucket" {
  description = "Name for bucket which stores failover website"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository. Changing it later recreates the repository and deletes its images"
  type        = string
}

variable "ecr_read_write_access_arns" {
  description = "ARNs of the IAM users/roles allowed to push and pull images in the ECR repository"
  type        = list(string)
}

variable "github_repo" {
  description = "Name of GitHub repository where Terraform pipeline will run"
  type        = string
}

variable "infra_control_destroy_schedule" {
  description = "Schedule expression for the daily shutdown of the primary environment"
  type        = string
  default     = "cron(0 22 * * ? *)"
}

variable "infra_control_cooldown_seconds" {
  description = "Minimum seconds between two deploys or shutdowns"
  type        = number
  default     = 600
}

variable "github_oidc_sub_prefix" {
  description = "Prefix of the GitHub OIDC sub claim (example: repo:OWNER@OWNER_ID/REPO@REPO_ID)"
  type        = string

  validation {
    condition     = startswith(var.github_oidc_sub_prefix, "repo:")
    error_message = "github_oidc_sub_prefix must start with \"repo:\"."
  }
}
