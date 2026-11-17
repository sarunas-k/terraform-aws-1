variable "name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the Application Load Balancer is placed"
  type        = string
}

variable "subnets" {
  description = "IDs of the subnets the Application Load Balancer is placed in"
  type        = list(string)
}

variable "access_logs_bucket_name" {
  description = "Name of the S3 bucket for ALB access logs. Must be globally unique"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the HTTPS listener. Must be in the same region as the ALB"
  type        = string
}
