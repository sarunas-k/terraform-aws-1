# ---------------------------
# VPC CIDR
# ---------------------------
variable "cidr" {
  description = "CIDR block of the VPC. Mask is between /16 and /20"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "Invalid mask"
  }

  validation {
    condition     = try(tonumber(split("/", var.cidr)[1]) >= 16 && tonumber(split("/", var.cidr)[1]) <= 20, false)
    error_message = "Mask must be between /16 and /20"
  }
}

# ---------------------------
# VPC Private subnets
# ---------------------------
variable "private_subnets" {
  description = "CIDR blocks of the private subnets, one per availability zone (2 or 3)"
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) >= 2 && length(var.private_subnets) <= 3
    error_message = "Provide 2 or 3 private subnets"
  }

  validation {
    condition     = alltrue([for c in var.private_subnets : can(cidrnetmask(c))])
    error_message = "Every private subnet must be a valid CIDR block"
  }

  validation {
    condition = alltrue([for c in var.private_subnets : try(
      tonumber(split("/", c)[1]) >= local.vpc_mask &&
      cidrsubnet("${cidrhost(c, 0)}/${local.vpc_mask}", 0, 0) == local.vpc_network,
    false)])
    error_message = "Every private subnet must be inside VPC cidr"
  }
}

# ---------------------------
# VPC Public subnets
# ---------------------------
variable "public_subnets" {
  description = "CIDR blocks of the public subnets, one per availability zone. Must have the same length as private_subnets"
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.public_subnets : can(cidrnetmask(c))])
    error_message = "Every public subnet must be a valid CIDR block"
  }

  validation {
    condition = alltrue([for c in var.public_subnets : try(
      tonumber(split("/", c)[1]) >= local.vpc_mask &&
      cidrsubnet("${cidrhost(c, 0)}/${local.vpc_mask}", 0, 0) == local.vpc_network,
    false)])
    error_message = "Every public subnet must be inside VPC cidr"
  }

  validation {
    condition     = length(var.public_subnets) == length(var.private_subnets)
    error_message = "public_subnets and private_subnets must be equal length"
  }
}

variable "name" {
  description = "Name of VPC"
  type        = string
}

