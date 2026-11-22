data "aws_region" "current" {}

data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "auto_scaling_group" {
  source  = "terraform-aws-modules/autoscaling/aws"

  name = var.name

  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  wait_for_capacity_timeout = 0
  health_check_type         = "ELB"
  vpc_zone_identifier       = var.vpc_zone_identifier #["subnet-1235678", "subnet-87654321"]

  traffic_source_attachments = {
    alb = {
      traffic_source_identifier = var.target_group_arn
      traffic_source_type       = "elbv2"
    }
  }

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 300
      min_healthy_percentage = 50
      max_healthy_percentage = 100
    }
  }

  launch_template_name        = var.launch_template_name
  launch_template_description = "Custom launch template"
  update_default_version      = true

  image_id          = data.aws_ami.ami.id
  instance_type     = "t3.micro"
  ebs_optimized     = true
  enable_monitoring = true

  user_data = base64encode(templatefile("${path.module}/scripts/user-data.sh.tftpl", {
    region                   = data.aws_region.current.region
    ecr_registry             = split("/", var.ecr_repository_url)[0]
    ecr_repository_url       = var.ecr_repository_url
    image_tag_parameter_name = var.image_tag_parameter_name
    container_port           = var.container_port
    infra_control_url        = var.infra_control_url
  }))

  create_iam_instance_profile = false
  iam_instance_profile_arn = aws_iam_instance_profile.ec2_app.arn

   metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        encrypted             = true
        volume_size           = 30
        volume_type           = "gp3"
      }
    }
  ]

  credit_specification = {
    cpu_credits = "standard"
  }

  security_groups = [aws_security_group.instances.id]

  tags = {
    AppRole = "compute"
  }
}

resource "aws_ssm_parameter" "image_tag" {
  name  = var.image_tag_parameter_name
  type  = "String"
  value = var.image_tag_initial

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    AppRole = "compute"
  }
}
