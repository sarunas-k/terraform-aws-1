state_file_bucket_name = "state-file-bucket-k23hg4j234"
state_file_keys        = ["infra/terraform.tfstate", "dns/terraform.tfstate"]
aws_region             = "eu-north-1"

bootstrap_role_trusted_principal_arns = [
  "arn:aws:iam::878947868165:user/sarunas",
  "arn:aws:iam::878947868165:role/dev-github-actions-apply",
]

state_file_keys_read = ["infra/terraform.tfstate"]

bootstrap_role_read_trusted_principal_arns = [
  "arn:aws:iam::878947868165:role/dev-github-actions-plan",
]
