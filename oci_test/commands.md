# Commands Used in Frontend Deployment and Troubleshooting

## 1. Frontend Build and Deployment

### Build Frontend
```bash
# Navigate to frontend directory and run build script
cd /home/rex/project/resume-editor/project/resume-modifier-frontend/ResMod-FE && ./build_and_push_oci.sh

# Force rebuild by removing last build hash
cd /home/rex/project/resume-editor/project/resume-modifier-frontend/ResMod-FE && rm -f .last_build && ./build_and_push_oci.sh

# Build with verbose output for debugging
docker buildx build --progress=plain --platform linux/amd64 -f Dockerfile --build-arg API_URL=https://oci.mintmelon.ca/market/api -t market-frontend:test .
```
**Purpose**: Build and push the frontend Docker image to OCI registry.

## 2. Kubernetes Pod Management

### Check Pod Status
```bash
# List all pods
kubectl get pods

# List specific frontend pods
kubectl get pods -l app=market-frontend

# Check pod status with wait
sleep 10 && kubectl get pods -l app=market-frontend
```
**Purpose**: Monitor the status of pods in the cluster.

### Restart Pod
```bash
# Delete pod to force recreation with new image
kubectl delete pod -l app=market-frontend
```
**Purpose**: Force Kubernetes to pull and use a new image.

### View Pod Logs
```bash
# View logs of specific pod
kubectl logs market-frontend-77467bbc6f-6tjcn

# View logs of all market backend pods
kubectl logs -l app=market-backend
```
**Purpose**: Debug issues by examining pod logs.

## 3. Docker System Management

### Clean Docker Resources
```bash
# Remove unused containers, networks, and images
docker system prune -f

# Aggressive cleanup including volumes
docker system prune -a -f --volumes
```
**Purpose**: Free up disk space by removing unused Docker resources.

### Check Docker Disk Usage
```bash
# Show Docker disk usage
docker system df
```
**Purpose**: Monitor Docker disk usage.

## 4. API Testing

### Test Market Backend API
```bash
# Test API endpoint with SSL verification disabled
curl -k https://oci.mintmelon.ca/market/api/job_market/newest
```
**Purpose**: Verify API endpoint functionality.

## 5. Ingress Configuration

### Apply Ingress Configuration
```bash
# Apply ingress configuration
cd /home/rex/project/resume-editor/deployment/oci_test && kubectl apply -f ingress.yaml
```
**Purpose**: Update ingress rules for routing traffic.

## Notes
- All commands assume you're working in the `/home/rex/project/resume-editor` directory unless specified otherwise
- The `-k` flag in curl commands disables SSL verification (use with caution in production)
- Pod names and IDs may vary between deployments
- Always check pod status after applying changes
- Monitor logs for any errors or issues

# Remove old journal logs
sudo journalctl --vacuum-time=2d

# Clean up package cache
sudo apt-get clean
sudo apt-get autoremove 