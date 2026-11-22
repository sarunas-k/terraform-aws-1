variable "aws_region" {
  description = "AWS Region for the provider"
  type        = string
}

variable "environment" {
  description = "Environment name, applied as the Environment tag on all resources"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "vpc_private_subnets" {
  description = "CIDR blocks of the private subnets, one per availability zone"
  type        = list(string)
}

variable "vpc_public_subnets" {
  description = "CIDR blocks of the public subnets, one per availability zone"
  type        = list(string)
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository. Changing it later recreates the repository and deletes its images"
  type        = string
}


variable "asg_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "asg_ec2_role_name" {
  description = "Name of the IAM role (and instance profile) assigned to the EC2 instances"
  type        = string
}

variable "asg_launch_template_name" {
  description = "Name of the launch template, unique per account and region"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
}

variable "asg_image_tag_parameter_name" {
  description = "Name of the SSM parameter holding the image tag the instances run"
  type        = string
}

variable "asg_image_tag_initial" {
  description = "Image tag stored in the SSM parameter when it is first created. Later changes are made by CI, not Terraform"
  type        = string
}

variable "infra_control_url" {
  description = "Function URL of the infra-control Lambda. Empty hides the app's shut-down button"
  type        = string
  default     = ""
}

variable "dns_zone_name" {
  description = "Name of the existing public hosted zone created by the dns/ root"
  type        = string
}

variable "dns_record_name" {
  description = "Fully qualified name of the alias record pointing at the ALB. Must be inside dns_zone_name"
  type        = string
}

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
}

variable "alb_logs_bucket_name" {
  description = "Name of the S3 bucket for ALB access logs. Must be globally unique"
  type        = string
}

variable "certificate_arn" {
  description = "Certificate ARN for the application"
  type        = string
}
