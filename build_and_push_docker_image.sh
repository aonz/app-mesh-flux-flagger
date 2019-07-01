#!/usr/bin/env bash

set -e

export $(grep -v '^#' .env | xargs)
export $(grep -v '^#' .env.local | xargs)

# Docker Image
cd app
IMAGE=app-mesh-flux-flagger
VERSION=$(node -p -e "require('./package.json').version")
$(aws ecr get-login --no-include-email --region ${REGION})
docker build -t ${IMAGE}:${VERSION} .
docker tag ${IMAGE}:${VERSION} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE}:${VERSION}
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE}:${VERSION}
cd ..