# Primary infrastructure root module
Main workload, created and destroyed on demand:
- VPC with endpoints
- Route 53 primary record
- Application Load Balancer
- Auto Scaling group of EC2 instances running the app containers

Applied by the pipelines.

## Structure

```
.
├── main.tf
├── ecr.tf
└── modules/
    ├── application-load-balancer/  # ALB
    ├── auto-scaling-group/         # Instances
    ├── route-53/                   # Primary DNS record
    └── vpc/
```

## Values from persistent/ root module

| Variable | Value |
|---|---|
| `ecr_repository_name` | name of the app registry |
| `certificate_arn` | ARN of the ALB certificate |
| `dns_zone_name` | public zone |
| `asg_image_tag_parameter_name` | SSM parameter with the app image tag |
| `infra_control_url` | shut-down Lambda URL for button in the app |

## Usage

Backend is the S3 bucket. State file key `infra/terraform.tfstate`.

```sh
terraform init
terraform plan
terraform apply
```

The app image tag is read from SSM, see root [README](../../README.md#releasing-a-new-app-image).
