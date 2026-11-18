module "vpc" {
  source = "./modules/vpc"

  name            = var.vpc_name
  cidr            = var.vpc_cidr
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets
}

module "auto_scaling_group" {
  source = "./modules/auto-scaling-group"

  depends_on = [module.vpc]

  name                 = var.asg_name
  ec2_role_name        = var.asg_ec2_role_name
  launch_template_name = var.asg_launch_template_name

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  ecr_repository_url       = data.aws_ecr_repository.app.repository_url
  image_tag_parameter_name = var.asg_image_tag_parameter_name
  image_tag_initial        = var.asg_image_tag_initial

  vpc_id              = module.vpc.vpc_id
  vpc_zone_identifier = module.vpc.private_subnet_ids

  alb_security_group_id = module.application_load_balancer.security_group_id
  target_group_arn      = module.application_load_balancer.target_group_arn
}

module "route_53" {
  source = "./modules/route-53"

  zone_name    = var.dns_zone_name
  record_name  = var.dns_record_name
  alb_dns_name = module.application_load_balancer.dns_name
  alb_zone_id  = module.application_load_balancer.zone_id
}

module "application_load_balancer" {
  source = "./modules/application-load-balancer"

  name                    = var.alb_name
  vpc_id                  = module.vpc.vpc_id
  subnets                 = module.vpc.public_subnet_ids
  access_logs_bucket_name = var.alb_logs_bucket_name
  certificate_arn         = var.certificate_arn

  # Lets this root be destroyed for demo purposes
  enable_deletion_protection = false
}

