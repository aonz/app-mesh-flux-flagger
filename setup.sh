
#!/usr/bin/env bash

set -e

export $(grep -v '^#' .env | xargs)
export $(grep -v '^#' .env.local | xargs)

# CDK
cd cdk
npm run build
npx cdk@0.36.1 deploy --require-approval never
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
aws eks --region ${REGION} update-kubeconfig --name AppMeshFluxFlagger
INSTANCE_PROFILE_ARN=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=AppMeshFluxFlaggerStack/EksCluster/EksNodes" | jq -r '.Reservations[0].Instances[0].IamInstanceProfile.Arn')
echo ${INSTANCE_PROFILE_ARN}
INSTANCE_PROFILE_ARN=${INSTANCE_PROFILE_ARN/arn:aws:iam::${ACCOUNT_ID}:instance-profile\//}
echo ${INSTANCE_PROFILE_ARN}
ROLE_ARN=$(aws iam get-instance-profile --instance-profile-name ${INSTANCE_PROFILE_ARN} | jq -r '.InstanceProfile.Roles[0].Arn')
echo ${ROLE_ARN}
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${ROLE_ARN}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF

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
helm repo add weaveworks https://weaveworks.github.io/flux
helm upgrade --install --values ./k8s/flux-values.yaml --namespace flux flux weaveworks/flux
fluxctl identity --k8s-fwd-ns flux
echo '  Optionally, add "export FLUX_FORWARD_NAMESPACE=flux" to the profile file.'
echo "  Done!!!\n"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: appmesh-system
EOF
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