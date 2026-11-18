variable "name" {
  description = "Name of container registry repository"
  type        = string
}

variable "read_write_access_arns" {
  description = "ARNs of the IAM users/roles allowed to push and pull images in the repository"
  type        = list(string)
}
