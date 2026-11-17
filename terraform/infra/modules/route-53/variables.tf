variable "zone_name" {
  description = "Name of the existing public hosted zone"
  type        = string
}

variable "record_name" {
  description = "Fully qualified name of the alias record. Must be inside the zone"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer the record points to"
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  type        = string
}
