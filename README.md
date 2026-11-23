# Portfolio project - AWS infrastructure managed by Terraform
App runs behind a load balancer with a failover page on CloudFront. The primary environment is deployed and shut down on demand from GitHub Actions.

## How it works

- Primary DNS record points to the load balancer of the primary environment, the secondary record to the failover page on CloudFront
- The primary environment is created on demand and destroyed every day at 22:00 UTC to save cost. While it is down, DNS serves the failover page
- Deploy and shut-down buttons on the pages start the Terraform pipelines through the [infra-control Lambda](terraform/persistent/content/lambda-infra-control/README.md)

## Project structure

```
.
├── .github/workflows/  # Plan, apply and destroy
├── src/                # Primary application source and Dockerfile
└── terraform/
    ├── bootstrap/      # Terraform root: remote state S3 bucket
    ├── infra/          # Terraform root: primary environment
    └── persistent/     # Terraform root: resources kept when the primary environment is shut down
```

See [infra/](terraform/infra/README.md) and [persistent/](terraform/persistent/README.md) for details.

## Pipelines

| Workflow | Trigger | Root |
|---|---|---|
| `terraform-plan` | pull request changing `terraform/infra/**` | `infra/` |
| `terraform-apply` | push to `main` changing `terraform/infra/**`, or dispatch | `infra/` |
| `terraform-destroy` | dispatch with input `confirm` = `destroy` | `infra/` |

- `bootstrap/` and `persistent/` are applied by hand

## GitHub repository secrets and variables

| Type | Name | Value |
|---|---|---|
| Secret | `AWS_TF_PLAN_ROLE_ARN` | output `github_actions_plan_role_arn` |
| Secret | `AWS_TF_APPLY_ROLE_ARN` | output `github_actions_apply_role_arn` |

```sh
gh secret set AWS_TF_PLAN_ROLE_ARN --repo sarunas-k/terraform-aws-1 \
  --body "<github_actions_plan_role_arn>"
gh secret set AWS_TF_APPLY_ROLE_ARN --repo sarunas-k/terraform-aws-1 \
  --body "<github_actions_apply_role_arn>"
```

## Getting started

Run these in order. Each `apply` is done by hand after reading the plan.

1. **Bootstrap**: remote state bucket and state roles

   ```sh
   terraform -chdir=terraform/bootstrap apply
   ```

2. **Persistent, part 1**: create the Lambda ECR repository first, so the image can be pushed

   ```sh
   terraform -chdir=terraform/persistent apply -target=module.infra_control_ecr
   ```

3. **Build and push the Lambda image**, writes the tag to SSM `/infra-control/image-tag`

   ```sh
   terraform/persistent/content/lambda-infra-control/build-and-push.sh
   ```

4. **Persistent, part 2**

   ```sh
   terraform -chdir=terraform/persistent apply
   ```

5. **Set the secret value**, not stored in Terraform state

   ```sh
   aws secretsmanager put-secret-value --secret-id infra-control \
     --secret-string '{"github_token": "<GITHUB_TOKEN>", "passcode": "<PASSCODE>"}'
   ```

6. **Set the GitHub repository secrets**, see [above](#github-repository-secrets-and-variables)

7. **Set the Lambda URL for the app button**, in `terraform/infra/terraform.tfvars`

   ```sh
   terraform -chdir=terraform/persistent output -raw infra_control_url
   ```

   ```hcl
   infra_control_url = "<output above>"
   ```

8. **Build and push the app image**, writes the tag to SSM `/app/image-tag`

   ```sh
   src/build-and-push.sh
   ```

## Releasing a new app image

Run the script again. The tag is a hash of the source files, so unchanged code is not pushed again.

```sh
src/build-and-push.sh
```

The SSM parameter `/app/image-tag` is created by `persistent/`, so it survives the daily destroy.
Instances read it when they start, so a new tag runs at the next deploy. To roll it out to a running
environment, start an instance refresh on the Auto Scaling group.

## Rotating the GitHub token or the passcode

Repeat step 5 of [Getting started](#getting-started). The Lambda caches the secret for up to 5 minutes.
