output "dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "zone_id" {
  description = "Hosted zone ID of the Application Load Balancer, used by Route 53 alias records"
  value       = module.alb.zone_id
}

output "target_group_arn" {
  description = "ARN of Application Load Balancer target group"
  value       = module.alb.target_groups["app-auto-scaling-group"].arn
}

output "security_group_id" {
  description = "Security Group ID of Application Load Balancer"
  value       = module.alb.security_group_id
}
