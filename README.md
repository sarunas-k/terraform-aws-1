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
- Apply and destroy run only from `main`, and their AWS role trusts only `main`. Protect the branch

## GitHub repository secrets and variables

| Type | Name | Value | Used by |
|---|---|---|---|
| Secret | `AWS_TF_PLAN_ROLE_ARN` | output `github_actions_plan_role_arn` | `terraform-plan` |
| Secret | `AWS_TF_APPLY_ROLE_ARN` | output `github_actions_apply_role_arn` | `terraform-apply`, `terraform-destroy` |

```sh
gh secret set AWS_TF_PLAN_ROLE_ARN --repo sarunas-k/terraform-aws-1 \
  --body "$(terraform -chdir=terraform/persistent output -raw github_actions_plan_role_arn)"
gh secret set AWS_TF_APPLY_ROLE_ARN --repo sarunas-k/terraform-aws-1 \
  --body "$(terraform -chdir=terraform/persistent output -raw github_actions_apply_role_arn)"
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

8. **Release the app image**, see below

## Releasing a new app image

1. Build and push the image

   ```sh
   src/build-and-push.sh
   ```

2. Set the tag it prints in `terraform/infra/terraform.tfvars` and merge to `main`

   ```hcl
   asg_image_tag_initial = "<tag>"
   ```

The SSM parameter `/app/image-tag` belongs to `infra/`, so the daily destroy deletes it and the next
deploy recreates it from `asg_image_tag_initial`. Changing only the SSM value is lost at the next
destroy. Creating the parameter by hand while `infra/` is down makes the next deploy fail with
`ParameterAlreadyExists`.

While `infra/` is up, Terraform ignores changes to the parameter's value, so a new tag takes effect
after the next destroy and deploy. To roll it out sooner, also set the SSM value and start an
instance refresh on the Auto Scaling group.

## Rotating the GitHub token or the passcode

Repeat step 5 of [Getting started](#getting-started). The Lambda caches the secret for up to 5 minutes.
