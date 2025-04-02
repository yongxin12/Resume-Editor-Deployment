#!/bin/bash

# Exit on error
set -e

echo "Installing Traefik..."

# Add Traefik helm repository
helm repo add traefik https://helm.traefik.io/traefik
helm repo update

# Create namespace if it doesn't exist
kubectl create namespace traefik --dry-run=client -o yaml | kubectl apply -f -

# Install Traefik
helm install traefik traefik/traefik \
  --namespace traefik \
  --values traefik-values.yaml

# Wait for Traefik to be ready
echo "Waiting for Traefik to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n traefik --timeout=300s

# Apply ingress routes
echo "Applying ingress routes..."
kubectl apply -f ingress.yaml

echo "Traefik installation complete!"
echo "You can access the dashboard at: https://oci.mintmelon.ca/dashboard/" 