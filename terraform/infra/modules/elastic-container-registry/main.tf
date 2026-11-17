module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = var.name

  repository_read_write_access_arns = var.read_write_access_arns
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "any",
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    AppRole = "storage"
  }
}
