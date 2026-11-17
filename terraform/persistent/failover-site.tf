# ---------------------------
# S3 bucket behind CloudFront via HTTPS
# ---------------------------
module "failover_site" {
  source = "./modules/static-website"

  bucket_name     = var.failover_site_bucket
  domain_name     = var.dns_record_name
  certificate_arn = module.acm_cloudfront.acm_certificate_arn
  content_dir     = "${path.module}/content/failover"

  # No caching while the site is in development. Remove this line to use the default (CachingOptimized)
  cache_policy_name = "Managed-CachingDisabled"
}

# ---------------------------
# Route 53 secondary failover record
# ---------------------------
resource "aws_route53_record" "failover_secondary" {
  zone_id        = module.zone.id
  name           = var.dns_record_name
  type           = "A"
  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = module.failover_site.distribution_domain_name
    zone_id                = module.failover_site.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
