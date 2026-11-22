# Persistent infrastructure root module
Resources kept when the primary environment (`infra/`) is shut down:
- Route 53 zone
- Route 53 secondary record
- TLS certificates
- Container registry
- Failover page in S3 bucket
- Lambda for remote primary infrastructure control

Applied manually, not by the pipelines.

## Structure

```
.
├── dns.tf                    # Route 53 zone, ACM certificates
├── ecr.tf                    # Container registry
├── failover-site.tf          # Failover site and Route 53 secondary record
├── github-oidc.tf
├── infra-control.tf          # Lambda for remote infrastructure control
├── content/
│   └── lambda-infra-control/ # Lambda container image source code
├── templates/
│   └── failover/             # Failover page template
└── modules/
    ├── elastic-container-registry/
    └── static-website/
```

## Outputs

| Output | Used for |
|---|---|
| `name_servers` | set at the domain registrar |
| `github_actions_plan_role_arn` | GitHub secret `AWS_TF_PLAN_ROLE_ARN` |
| `github_actions_apply_role_arn` | GitHub secret `AWS_TF_APPLY_ROLE_ARN` |
| `infra_control_url` | `infra_control_url` in `infra/terraform.tfvars` |

## Usage

Backend is the S3 bucket. State file key `dns/terraform.tfstate`.

```sh
terraform init
terraform plan
terraform apply
```
