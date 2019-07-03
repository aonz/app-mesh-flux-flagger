# App Mesh x Flux x Flagger

## Setup
- Fork this repo.
- Add the missing values on the `.env` file.
- Edit the `./k8s/flux-values.yaml` and replace the `url:` value.
- Edit the `./flux/releases/aws-appmesh.yaml` and replace the `git:` value.
- Run `./setup.sh`.
- Follow this [instruction](https://github.com/weaveworks/flux/blob/master/site/get-started.md#giving-write-access) to give Flux access to the repo.

## Canary Release
- Run `fluxctl -n flagger list-workloads | grep flagger:deployment/app`.
- Run `fluxctl -n flagger list-images`.
- Run `kubectl -n flagger get pod -l app=loadtester`, make sure the `READY` column shows `4/4`. Otherwise, kill the pod and wait for the new one to come up.
- Open another terminal,
  - Run `kubectl exec -it $(kubectl -n flagger get pod -l app=loadtester -o jsonpath='{.items[0].metadata.name}') bash`.
  - Run `while true; curl app.flagger/version; echo ""; do sleep 1; done;`.
- Run `./canary-release.sh`.
- Check the behavior on terminal and App Mesh on AWS console.
- Wait the process complete (Slack notificaiton).
- Run `fluxctl -n flagger list-workloads | grep flagger:deployment/app`.
- Run `fluxctl -n flagger list-images`.