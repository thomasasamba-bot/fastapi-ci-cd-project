#!/bin/bash
# setup-kube.sh - Automatically configures local kubectl via S3 (Zero-SSH)

if [ -z "$1" ]; then
    echo "Usage: ./setup-kube.sh <PUBLIC_IP> [BUCKET_NAME]"
    exit 1
fi

PUBLIC_IP=$1
BUCKET_NAME=${2:-"fastapi-ci-cd-state-bucket"} # Default or provided

echo "Fetching K3s config from S3 bucket: $BUCKET_NAME..."
# Backup existing config
if [ -f ~/.kube/config ]; then
    cp ~/.kube/config ~/.kube/config.bak.$(date +%Y%m%d%H%M%S)
fi

# Fetch from S3
aws s3 cp s3://$BUCKET_NAME/dev/kubeconfig ~/.kube/config

if [ $? -eq 0 ]; then
    echo "Success! Your local kubectl is now linked to the AWS cluster."
    echo "Testing connection..."
    kubectl get nodes
else
    echo "--------------------------------------------------------------------------------"
    echo "Error: Could not fetch config from S3."
    echo "This usually means the AWS instance is still booting (takes ~2-3 minutes)."
    echo "Please wait a moment and try running this script again."
    echo "--------------------------------------------------------------------------------"
    echo "Bucket: $BUCKET_NAME"
fi
