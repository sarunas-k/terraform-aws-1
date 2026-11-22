# ---------------------------
# General
# ---------------------------
aws_region  = "eu-north-1"
environment = "dev"

# ---------------------------
# DNS
# ---------------------------
dns_zone_name   = "dev.saruno.lt"
dns_record_name = "aws1.dev.saruno.lt"

# ---------------------------
# Failover site
# ---------------------------
failover_site_bucket = "failover-site-bucket-89234146"

# ---------------------------
# Elastic Container Registry
# ---------------------------
ecr_repository_name        = "app"
ecr_read_write_access_arns = ["arn:aws:iam::878947868165:user/sarunas"]

# ---------------------------
# GitHub Actions pipelines
# ---------------------------
github_repo            = "sarunas-k/terraform-aws-1"
github_oidc_sub_prefix = "repo:sarunas-k@18898564/terraform-aws-1@1461519093"
