# ---------------------------
# Public DNS zone for project
# ---------------------------
module "zone" {
  source = "terraform-aws-modules/route53/aws"

  name    = var.dns_zone_name
  comment = "Public zone for demo project"
}

# ---------------------------
# TLS Certificate for ALB (eu-north-1)
# ---------------------------
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = var.dns_record_name
  zone_id     = module.zone.id

  validation_method = "DNS"

  wait_for_validation = true
}

# ---------------------------
# TLS Certificate for CloudFront (us-east-1)
# ---------------------------
module "acm_cloudfront" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = var.dns_record_name
  zone_id     = module.zone.id

  validation_method   = "DNS"
  wait_for_validation = true

  providers = {
    aws = aws.us_east_1
  }
}
