# Lambda infra-control
Starts the `terraform-apply` and `terraform-destroy` GitHub workflows for the primary environment. Used by the deploy and shut-down buttons and by the daily shutdown schedule.

## Project structure

```
.
├── app.py              # Lambda handler: function URL requests and scheduler events
├── control.py          # Rules: no overlapping runs, no rapid repeats
├── github_api.py       # GitHub REST calls
├── Dockerfile
├── build-and-push.sh   # Build, push to ECR, write image tag to SSM
└── tests/
```

## Routes

| Caller | Event | GitHub workflow |
|---|---|---|
| Failover page button | `POST /wake` | `terraform-apply` |
| Primary app button | `POST /destroy` | `terraform-destroy` |
| EventBridge Scheduler | `{"source": "scheduler", "action": "destroy"}` | `terraform-destroy` |

Request body for the buttons: `{"passcode": "..."}`

| Response | Meaning |
|---|---|
| 202 | Workflow started |
| 401 | Wrong passcode |
| 409 | A run is already in progress |
| 429 | Another run started within the cooldown or Lambda is busy with another request |
| 502 | GitHub could not be reached |

## Prerequisites

| What | Details |
|---|---|
| Tools | `podman`, AWS CLI, `terraform`, `python3` |
| ECR repository | `infra-control`, created before the image is pushed |
| Image | pushed with `build-and-push.sh`, which writes its tag to SSM `/infra-control/image-tag` |

## Push Lambda container image

Run to push the image, then apply `terraform/persistent`:

```sh
./build-and-push.sh
```
