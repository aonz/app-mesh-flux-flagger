#!/usr/bin/env bash

set -e

export $(grep -v '^#' .env | xargs)
export $(grep -v '^#' .env.local | xargs)

# Docker Images
$(aws ecr get-login --no-include-email --region ${REGION})
APP=api
cd ${APP}
IMAGE=app-mesh-flux-flagger-${APP}
VERSION=$(node -p -e "require('./package.json').version")
docker build -t ${IMAGE}:${VERSION} .
docker tag ${IMAGE}:${VERSION} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE}:${VERSION}
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE}:${VERSION}
cd ..
APP=backend
cd ${APP}
IMAGE=app-mesh-flux-flagger-${APP}
VERSION=$(node -p -e "require('./package.json').version")
docker build -t ${IMAGE}:${VERSION} .
docker tag ${IMAGE}:${VERSION} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE}:${VERSION}
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${IMAGE}:${VERSION}
cd ..