# App Mesh x Flux x Flagger

## Setup
- Fork this repo.
- Add the missing values on the `.env` file.
- Edit the `./k8s/flux-values.yaml` and replace the `url:` value.
- Edit the `./flux/releases/aws-appmesh.yaml` and replace the `git:` value.
- Run `./setup.sh`.
- Follow this [instruction](https://github.com/weaveworks/flux/blob/master/site/get-started.md#giving-write-access) to give Flux access to the repo.