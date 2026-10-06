#!/usr/bin/env bash
# Build & push to GCP Artifact Registry.
# Usage: PROJECT_ID=my-proj ./build-push.sh   (optional: REGION, REPO, IMAGE_NAME, TAG, PLATFORM)
set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID}"
REGION="${REGION:-asia-southeast2}"
REPO="${REPO:-apps}"
IMAGE_NAME="${IMAGE_NAME:-apm-elastics}"
TAG="${TAG:-$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"
PLATFORM="${PLATFORM:-linux/amd64}" # Cloud Run/GKE default; Mac ARM would otherwise build arm64

IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/${IMAGE_NAME}"

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

gcloud artifacts repositories describe "$REPO" --location "$REGION" --project "$PROJECT_ID" >/dev/null 2>&1 \
  || gcloud artifacts repositories create "$REPO" --repository-format=docker \
       --location "$REGION" --project "$PROJECT_ID"

docker buildx build \
  --platform "$PLATFORM" \
  --build-arg VERSION="$TAG" \
  -t "$IMAGE:$TAG" -t "$IMAGE:latest" \
  --push .

echo "pushed $IMAGE:$TAG"
