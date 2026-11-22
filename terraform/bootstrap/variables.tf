variable "state_file_bucket_name" {
  description = "Name for Terraform state file in S3 bucket"
  type        = string
}

variable "state_file_keys" {
  description = "Keys of the Terraform state files in the S3 bucket the bootstrap role may manage"
  type        = list(string)
}

variable "bootstrap_role_trusted_principal_arns" {
  description = "ARNs of the users/roles allowed to assume the bootstrap-role role"
  type        = list(string)
}

variable "state_file_keys_read" {
  description = "Keys of the Terraform state files in the S3 bucket the read-only bootstrap-role-read may read"
  type        = list(string)
}

variable "bootstrap_role_read_trusted_principal_arns" {
  description = "ARNs of the users/roles allowed to assume the read-only bootstrap-role-read role"
  type        = list(string)
}

variable "aws_region" {
  description = "AWS Region for the provider"
  type        = string
}
