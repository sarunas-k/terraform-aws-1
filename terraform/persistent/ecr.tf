# ---------------------------
# Elastic Container Rgistry
# ---------------------------
module "elastic_container_registry" {
  source = "./modules/elastic-container-registry"

  name                   = var.ecr_repository_name
  read_write_access_arns = var.ecr_read_write_access_arns
}

# ---------------------------
# App image tag, written by src/build-and-push.sh
# ---------------------------
resource "aws_ssm_parameter" "app_image_tag" {
  name  = "/app/image-tag"
  type  = "String"
  value = "not-built-yet"

  lifecycle {
    ignore_changes = [value]
  }
}
