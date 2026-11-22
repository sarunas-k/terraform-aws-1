# ---------------------------
# General
# ---------------------------
aws_region  = "eu-north-1"
environment = "dev"

# ---------------------------
# VPC
# ---------------------------
vpc_name = "vpc"
vpc_cidr = "10.0.0.0/16"

vpc_private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
vpc_public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# ---------------------------
# Elastic Container Registry
# ---------------------------
ecr_repository_name        = "app"

# ---------------------------
# Auto Scaling Group
# ---------------------------
asg_name                     = "app"
asg_ec2_role_name            = "ec2-app"
asg_launch_template_name     = "app"
asg_min_size                 = 3
asg_max_size                 = 3
asg_desired_capacity         = 3
asg_image_tag_parameter_name = "/app/image-tag"
asg_image_tag_initial        = "app-0b4362b24b86"

# ---------------------------
# Infra control
# ---------------------------
infra_control_url = "https://reu4izrlv5qburoakeip55hedi0wywtk.lambda-url.eu-north-1.on.aws/"

# ---------------------------
# DNS
# ---------------------------
dns_zone_name   = "dev.saruno.lt"
dns_record_name = "aws1.dev.saruno.lt"

# ---------------------------
# Application Load Balancer
# ---------------------------
alb_name             = "alb"
alb_logs_bucket_name = "alb-logs-878947868165-eu-north-1"

# ---------------------------
# Certificate Manager
# ---------------------------
certificate_arn = "arn:aws:acm:eu-north-1:878947868165:certificate/c0eb20e3-736a-4533-8ccf-6fb0b570da24"