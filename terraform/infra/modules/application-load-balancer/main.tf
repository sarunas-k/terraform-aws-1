module "alb" {
  source = "terraform-aws-modules/alb/aws"

  depends_on = [aws_s3_bucket_policy.access_logs]

  name    = var.name
  vpc_id  = var.vpc_id
  subnets = var.subnets

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  access_logs = {
    bucket = aws_s3_bucket.access_logs.id
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate_arn

      forward = {
        target_group_key = "app-auto-scaling-group"
      }
    }
  }

  target_groups = {
    app-auto-scaling-group = {
      name_prefix       = "app-"
      protocol          = "HTTP"
      port              = 8080
      create_attachment = false
      health_check      = { path = "/health" }
    }
  }
}