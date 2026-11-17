resource "aws_security_group" "instances" {
  name        = "${var.name}-instances"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  tags = { 
    AppRole = "compute"
  }
}

resource "aws_vpc_security_group_ingress_rule" "instances_ipv4" {
  security_group_id             = aws_security_group.instances.id
  referenced_security_group_id  = var.alb_security_group_id
  from_port                     = 8080
  ip_protocol                   = "tcp"
  to_port                       = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.instances.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # All ports
}
