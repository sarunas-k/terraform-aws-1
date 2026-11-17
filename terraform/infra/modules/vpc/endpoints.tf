module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc.vpc_id

  # Single AZ for interface endpoints to save cost. 
  # Other AZs reach them over VPC routing
  subnet_ids = [module.vpc.private_subnets[0]]

  create_security_group     = true
  security_group_name_prefix = "vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_tags        = { Purpose = "vpc-endpoints" }

  timeouts = {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
    },
    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      private_dns_enabled = true
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      private_dns_enabled = true
    },
    rds = {
      service             = "rds"
      service_type        = "Interface"
      private_dns_enabled = true
    },
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = true
    }
    # ssmmessages = {
    #   service             = "ssmmessages"
    #   service_type        = "Interface"
    #   private_dns_enabled = true
    # }
  }
}