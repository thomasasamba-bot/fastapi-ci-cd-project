#!/bin/bash
# setup-kube.sh - Automatically configures local kubectl for the showcase project

if [ -z "$1" ]; then
    echo "Usage: ./setup-kube.sh <PUBLIC_IP>"
    exit 1
fi

PUBLIC_IP=$1

echo "Fetching K3s config from $PUBLIC_IP..."
# Backup existing config
if [ -f ~/.kube/config ]; then
    cp ~/.kube/config ~/.kube/config.bak.$(date +%Y%m%d%H%M%S)
fi

scp -o StrictHostKeyChecking=no ubuntu@$PUBLIC_IP:/etc/rancher/k3s/k3s.yaml ~/.kube/config

echo "Updating config with Public IP..."
# Support for both macOS and Linux sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/127.0.0.1/$PUBLIC_IP/g" ~/.kube/config
else
    sed -i "s/127.0.0.1/$PUBLIC_IP/g" ~/.kube/config
fi

echo "Success! Your local kubectl is now linked to the AWS cluster."
echo "Testing connection..."
kubectl get nodes
