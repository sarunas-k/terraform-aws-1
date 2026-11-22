#!/usr/bin/env bash
# Builds and pushes the app image. Needs podman and the AWS CLI.
# Prints the tag to set as asg_image_tag_initial in terraform/infra/terraform.tfvars.
set -euo pipefail

REGION="${AWS_REGION:-eu-north-1}"
REPOSITORY="${REPOSITORY:-app}"
CLI="podman"

cd "$(dirname "$0")"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE="${REGISTRY}/${REPOSITORY}"

if ! aws ecr describe-repositories --region "${REGION}" --repository-names "${REPOSITORY}" > /dev/null 2>&1; then
  echo "ECR repository ${REPOSITORY} does not exist. Apply terraform/persistent first."
  exit 1
fi

HASH=$(find Dockerfile requirements.txt app -type f -not -path '*/__pycache__/*' -not -name '*.pyc' \
  | LC_ALL=C sort | xargs cat | shasum -a 256 | cut -c1-12)
TAG="app-${HASH}"

echo "Account:  ${ACCOUNT_ID}"
echo "Image:    ${IMAGE}:${TAG}"
read -r -p "Build and push to this account? [y/N] " answer
[ "${answer}" = "y" ] || { echo "Aborted."; exit 1; }

if aws ecr describe-images --region "${REGION}" --repository-name "${REPOSITORY}" \
  --image-ids imageTag="${TAG}" > /dev/null 2>&1; then
  echo "Image ${TAG} is already in ECR, skipping build and push."
else
  "${CLI}" build --platform linux/amd64 --format docker -t "${IMAGE}:${TAG}" .

  aws ecr get-login-password --region "${REGION}" \
    | "${CLI}" login --username AWS --password-stdin "${REGISTRY}"

  "${CLI}" push --format v2s2 "${IMAGE}:${TAG}"
fi

echo
echo "Done. Set asg_image_tag_initial = \"${TAG}\" in terraform/infra/terraform.tfvars"
echo "Merging that to main runs the apply pipeline."
