# ---------------------------
# Data and variables
# ---------------------------
data "aws_availability_zones" "available" {
  state = "available"

  lifecycle {
    postcondition {
      condition     = length(self.names) >= length(var.private_subnets)
      error_message = "The Region has fewer available availability zones than the number of subnets requested."
    }
  }
}

locals {
  az_count = length(var.private_subnets)
  # Resolving AZs from number of subnets
  azs         = slice(data.aws_availability_zones.available.names, 0, local.az_count)
  vpc_mask    = try(tonumber(split("/", var.cidr)[1]), null)
  vpc_network = try(cidrsubnet(var.cidr, 0, 0), null)
}

# ---------------------------
# VPC module definition
# ---------------------------
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name
  cidr = var.cidr

  azs             = local.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # Not using NAT to save cost for demo
  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    AppRole = "network"
  }
}
