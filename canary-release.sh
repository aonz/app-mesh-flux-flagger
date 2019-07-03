#!/usr/bin/env bash

set -e

export $(grep -v '^#' .env | xargs)
export $(grep -v '^#' .env.local | xargs)

cd app
npm version major
VERSION=$(node -p -e "require('./package.json').version")
cd ..
git pull
git commit -a -m "Release version: ${VERSION}"
git push -u origin --force
sh ./build_and_push_docker_image.sh

