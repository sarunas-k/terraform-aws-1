variable "aws_region" {
  description = "AWS Region for the provider"
  type        = string
}

variable "environment" {
  description = "Environment name, applied as the Environment tag on all resources"
  type        = string
}

variable "dns_zone_name" {
  description = "Domain of the DNS zone"
  type        = string
}

variable "dns_record_name" {
  description = "Subdomain of the DNS record"
  type        = string
}

variable "failover_site_bucket" {
  description = "Name for bucket which stores failover website"
  type        = string
}
