variable "ec2_role_name" {
    type        = string
    description = "Name of the role assigned to EC2 instances"
}

variable "name" {
    type        = string
    description = "Name of Auto Scaling Group"
}

variable "min_size" {
    type        = number
    description = "Min size of instances for Auto Scaling Group"
}

variable "max_size" {
    type        = number
    description = "Max size of instances for Auto Scaling Group"
}

variable "desired_capacity" {
    type        = number
    description = "Desired size of instances for Auto Scaling Group"
}

variable "vpc_id" {
    type        = string
    description = "ID of VPC where Auto Scaling Group is placed"
}

variable "alb_security_group_id" {
    type        = string
    description = "Security group ID of Application Load Balancer which points to Auto Scaling Group"
}

variable "vpc_zone_identifier" {
    type        = list(string)
    description = "A list of subnet IDs to launch resources in"
}

variable "launch_template_name" {
    type        = string
    description = "Name of launch template for Auto Scaling Group instances"
}

variable "ecr_repository_url" {
    type        = string
    description = "URL of the ECR repository the container image is pulled from, without a tag"
}

variable "image_tag_parameter_name" {
    type        = string
    description = "Name of the SSM parameter holding the image tag to run"
}

variable "image_tag_initial" {
    type        = string
    description = "Initial image tag to be stored in SSM parameter"
}

variable "container_port" {
    type        = number
    description = "Port the container listens on, published on the same host port"
    default     = 8080
}

variable "target_group_arn" {
  description = "ARN of the Application Load Balancer target group the instances are registered with"
  type        = string
}
