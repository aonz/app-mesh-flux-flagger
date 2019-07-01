
#!/usr/bin/env bash

set -e

export $(grep -v '^#' .env | xargs)
export $(grep -v '^#' .env.local | xargs)

# CDK
cd cdk
npm run build
npx cdk@0.36.0 deploy --require-approval never
cd ..

# Docker Image
sh ./build_and_push_docker_image.sh
