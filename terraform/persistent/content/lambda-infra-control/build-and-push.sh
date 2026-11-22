#!/usr/bin/env bash
# Builds and pushes the infra-control image. Writes its tag to SSM.
set -euo pipefail

REGION="${AWS_REGION:-eu-north-1}"
REPOSITORY="${REPOSITORY:-infra-control}"
TAG_PARAMETER="${TAG_PARAMETER:-/infra-control/image-tag}"
CLI="podman"

cd "$(dirname "$0")"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE="${REGISTRY}/${REPOSITORY}"

if ! aws ecr describe-repositories --region "${REGION}" --repository-names "${REPOSITORY}" > /dev/null 2>&1; then
  echo "ECR repository ${REPOSITORY} does not exist."
  exit 1
fi

TAG="src-$(cat Dockerfile app.py control.py github_api.py | shasum -a 256 | cut -c1-12)"

echo "Account:  ${ACCOUNT_ID}"
echo "Image:    ${IMAGE}:${TAG}"
read -r -p "Build and push to this account? [y/N] " answer
[ "${answer}" = "y" ] || { echo "Aborted."; exit 1; }

PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests

if aws ecr describe-images --region "${REGION}" --repository-name "${REPOSITORY}" \
  --image-ids imageTag="${TAG}" > /dev/null 2>&1; then
  echo "Image ${TAG} is already in ECR, skipping build and push."
else
  "${CLI}" build --platform linux/amd64 --format docker -t "${IMAGE}:${TAG}" .

  aws ecr get-login-password --region "${REGION}" \
    | "${CLI}" login --username AWS --password-stdin "${REGISTRY}"

  "${CLI}" push --format v2s2 "${IMAGE}:${TAG}"
fi

aws ssm put-parameter --region "${REGION}" --name "${TAG_PARAMETER}" \
  --type String --overwrite --value "${TAG}" > /dev/null

echo
echo "Done. SSM ${TAG_PARAMETER} = ${TAG}"
echo "Next: terraform -chdir=terraform/persistent plan, then apply."
