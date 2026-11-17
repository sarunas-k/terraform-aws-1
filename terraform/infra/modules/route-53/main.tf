# ---------------------------
# Existing public zone
# ---------------------------
data "aws_route53_zone" "this" {
  name         = var.zone_name
  private_zone = false
}

# ---------------------------
# Alias record pointing to ALB
# ---------------------------
resource "aws_route53_record" "alb" {
  zone_id        = data.aws_route53_zone.this.zone_id
  name           = var.record_name
  type           = "A"
  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
