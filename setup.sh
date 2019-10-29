
#!/usr/bin/env bash

set -e

export $(grep -v '^#' .env | xargs)
export $(grep -v '^#' .env.local | xargs)

sed -i '' "s/ACCOUNT_ID/${ACCOUNT_ID//\//\\/}/" ./flux/releases/app.yaml
git commit -a -m "Set app repo."
git push -u origin --force

# CDK
cd cdk
npm run build
npx cdk@1.15.0 deploy --require-approval never
cd ..

# Docker Image
sh ./build_and_push_docker_image.sh

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
aws eks --region ${REGION} update-kubeconfig --name AppMeshFluxFlagger --role-arn arn:aws:iam::${ACCOUNT_ID}:role/app-mesh-flux-flagger

# Helm
if ! which helm > /dev/null; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install kubernetes-helm
  else
    echo "helm should be installed"
    exit 1
  fi
fi
echo 'Installing Helm...'
kubectl apply -f ./k8s/rbac-config.yaml
helm init --service-account tiller --history-max 200
echo "  Done!!!\n"

# Flux
if ! which fluxctl > /dev/null; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install fluxctl
  else
    echo "fluxctl should be installed"
    exit 1
  fi
fi
echo 'Installing Flux...'
helm repo add fluxcd https://charts.fluxcd.io
helm upgrade --install --values ./k8s/flux-values.yaml --namespace flux flux fluxcd/flux
fluxctl identity --k8s-fwd-ns flux
echo '  Optionally, add "export FLUX_FORWARD_NAMESPACE=flux" to the profile file.'
echo "  Done!!!\n"

kubectl apply -f https://raw.githubusercontent.com/weaveworks/flagger/master/artifacts/flagger/crd.yaml
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

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: appmesh-system
EOF
kubectl apply -f https://raw.githubusercontent.com/aws/eks-charts/master/stable/appmesh-controller/crds/crds.yaml
