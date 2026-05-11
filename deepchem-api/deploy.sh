#!/usr/bin/env bash
# Usage: ./deploy.sh <GCP_PROJECT_ID> [REGION]
# Example: ./deploy.sh my-project-123 asia-northeast1
set -euo pipefail

PROJECT_ID="${1:?Usage: ./deploy.sh <PROJECT_ID> [REGION]}"
REGION="${2:-asia-northeast1}"
SERVICE="deepchem-api"
IMAGE="gcr.io/${PROJECT_ID}/${SERVICE}"

echo "=== DeepChem API deploy ==="
echo "  Project : ${PROJECT_ID}"
echo "  Region  : ${REGION}"
echo "  Image   : ${IMAGE}"
echo ""

# 1. Build & push
echo "[1/3] Building Docker image (model training included — may take ~20 min)..."
docker build --tag "${IMAGE}:latest" .
docker push "${IMAGE}:latest"

# 2. Deploy Cloud Run
echo "[2/3] Deploying to Cloud Run..."
gcloud run deploy "${SERVICE}" \
  --image "${IMAGE}:latest" \
  --region "${REGION}" \
  --platform managed \
  --allow-unauthenticated \
  --memory 4Gi \
  --cpu 2 \
  --timeout 300 \
  --concurrency 10 \
  --min-instances 0 \
  --max-instances 3 \
  --project "${PROJECT_ID}"

# 3. Print URL
echo "[3/3] Deployment complete."
echo ""
echo "Service URL:"
gcloud run services describe "${SERVICE}" \
  --region "${REGION}" \
  --project "${PROJECT_ID}" \
  --format "value(status.url)"
