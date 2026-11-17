# Portfolio project - AWS managed by Terraform
Purpose is to showcase using Terraform to provision infrastructure on AWS.

## Project structure

```
.
├── src/            # Application source and Dockerfile
│   └── app/
│       ├── static/
│       └── templates/
└── terraform/
    ├── bootstrap/  # Remote state S3 bucket and bootstrap IAM role
    ├── infra/      # Main workload stack (can be created/destroyed on demand)
    │   └── modules/
    │       ├── application-load-balancer/
    │       ├── auto-scaling-group/
    │       ├── elastic-container-registry/
    │       ├── route-53/
    │       └── vpc/
    └── persistent/ # Resources persisted when I shut down the primary app
        ├── content/
        │   └── failover/
        └── modules/
            └── static-website/
```

