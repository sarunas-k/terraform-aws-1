# ---------------------------
# Elastic Container Rgistry
# ---------------------------
module "elastic_container_registry" {
  source = "./modules/elastic-container-registry"

  name                   = var.ecr_repository_name
  read_write_access_arns = var.ecr_read_write_access_arns
}
