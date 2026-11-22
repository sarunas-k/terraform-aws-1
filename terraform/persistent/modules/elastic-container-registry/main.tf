# ---------------------------
# Lifecycle policy document to keep last 30 images
# ---------------------------
data "aws_ecr_lifecycle_policy_document" "this" {
  rule {
    priority    = 1
    description = "Keep last 30 images"

    selection {
      tag_status   = "any"
      count_type   = "imageCountMoreThan"
      count_number = 30
    }
  }
}

# ---------------------------
# Container registry
# ---------------------------
module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = var.name

  repository_read_write_access_arns  = var.read_write_access_arns
  repository_lambda_read_access_arns = var.lambda_read_access_arns
  repository_lifecycle_policy        = data.aws_ecr_lifecycle_policy_document.this.json

  tags = {
    AppRole = "storage"
  }
}
