
#!/usr/bin/env bash

set -e

export $(grep -v '^#' .env | xargs)
export $(grep -v '^#' .env.local | xargs)

sed -i '' "s/ACCOUNT_ID/${ACCOUNT_ID//\//\\/}/" ./flux/releases/api.yaml
sed -i '' "s/ACCOUNT_ID/${ACCOUNT_ID//\//\\/}/" ./flux/releases/backend.yaml
git checkout -b gitops
git commit -a -m "Set app repo."
git push --set-upstream origin gitops --force

# CDK
cd cdk
npm run build
npx cdk@1.27.0 bootstrap
npx cdk@1.27.0 deploy --require-approval never
cd ..

# Docker Image
sh ./build_and_push_docker_images.sh

# EKS
if ! which aws-iam-authenticator > /dev/null; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install aws-iam-authenticator
  else
    echo "aws-iam-authenticator should be installed"
    exit 1
  fi
fi
if ! which jq > /dev/null; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install jq
  else
    echo "jq should be installed"
    exit 1
  fi
fi
aws eks --region ${REGION} update-kubeconfig --name AppMeshFluxFlagger --role-arn arn:aws:iam::${ACCOUNT_ID}:role/app-mesh-flux-flagger-masters-role

# Helm
echo 'Installing Helm...'
if ! which helm > /dev/null; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install kubernetes-helm
  else
    echo "helm should be installed"
    exit 1
  fi
fi
echo "  Done!!!\n"

# Flux
echo 'Installing Flux...'
if ! which fluxctl > /dev/null; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install fluxctl
  else
    echo "fluxctl should be installed"
    exit 1
  fi
fi
kubectl apply -f ./flux/resources/flux-namespace.yaml 
helm repo add fluxcd https://charts.fluxcd.io
helm upgrade --install --values ./k8s-values/flux-values.yaml \
  --namespace flux flux fluxcd/flux
fluxctl identity --k8s-fwd-ns flux
helm upgrade --install --values ./k8s-values/helm-operator-values.yaml \
  --namespace flux helm-operator fluxcd/helm-operator
echo '  Optionally, add "export FLUX_FORWARD_NAMESPACE=flux" to the profile file.'
echo "  Done!!!\n"

kubectl apply -f ./flux/resources/appmesh-system-namespace.yaml

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: flagger
  namespace: appmesh-system
data:
  values.yaml: |
    slack:
      url: ${FLAGGER_SLACK_WEBHOOK_URL}
EOF

