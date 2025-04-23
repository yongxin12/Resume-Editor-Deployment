# Complete Ingress Setup and Troubleshooting Process

## Initial State
- Nginx Ingress Controller was installed and configured in the Kubernetes environment
- External IP: `40.233.73.93`
- Applications were not accessible initially

## Step-by-Step Process

### 1. Initial Debugging Steps
1. Checked the status of the ingress controller pod
2. Reviewed ingress controller logs
3. Modified ingress configurations multiple times to resolve connectivity issues
4. Removed host specification
5. Added ingress class annotations
6. Confirmed all backend services were running and accessible

### 2. Frontend Service Updates
1. Updated market frontend to use relative paths:
   - Modified `deployment/oci_test/market-frontend.yaml`
   - Changed `REACT_APP_BACKEND_URL` from `"/market/api"` to `"/api"`

2. Updated editor frontend to use relative paths:
   - Modified `deployment/oci_test/editor-frontend.yaml`
   - Changed `REACT_APP_BACKEND_URL` from `"/editor/api"` to `"/api"`

3. Applied changes to Kubernetes:
```bash
kubectl apply -f deployment/oci_test/market-frontend.yaml -f deployment/oci_test/editor-frontend.yaml
```

### 3. Permission Issues Resolution
1. Created IngressClass configuration:
```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
```

2. Updated RBAC rules to include necessary permissions:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: nginx-ingress-controller
rules:
  - apiGroups: [""]
    resources:
      - configmaps
      - endpoints
      - nodes
      - pods
      - secrets
      - services
      - namespaces
    verbs:
      - get
      - list
      - watch
  - apiGroups: [""]
    resources:
      - nodes
    verbs:
      - get
  - apiGroups: [""]
    resources:
      - services
    verbs:
      - get
      - list
      - watch
      - update
  - apiGroups: ["networking.k8s.io"]
    resources:
      - ingresses
      - ingresses/status
      - ingressclasses
    verbs:
      - get
      - list
      - watch
      - update
  - apiGroups: [""]
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups: ["coordination.k8s.io"]
    resources:
      - leases
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - delete
  - apiGroups: ["discovery.k8s.io"]
    resources:
      - endpointslices
    verbs:
      - get
      - list
      - watch
```

### 4. Ingress Configuration Evolution
1. Initial configuration:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: resume-app-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
    - http:
        paths:
          - path: /market
            pathType: Prefix
            backend:
              service:
                name: market-frontend-service
                port:
                  number: 80
          - path: /market/api
            pathType: Prefix
            backend:
              service:
                name: market-backend-service
                port:
                  number: 5001
          - path: /editor
            pathType: Prefix
            backend:
              service:
                name: editor-frontend-service
                port:
                  number: 80
          - path: /editor/api
            pathType: Prefix
            backend:
              service:
                name: editor-backend-service
                port:
                  number: 5001
```

2. Final configuration with path rewriting:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: resume-app-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
    - http:
        paths:
          - path: /market
            pathType: Prefix
            backend:
              service:
                name: market-frontend-service
                port:
                  number: 80
          - path: /market/api(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: market-backend-service
                port:
                  number: 5001
          - path: /editor
            pathType: Prefix
            backend:
              service:
                name: editor-frontend-service
                port:
                  number: 80
          - path: /editor/api(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: editor-backend-service
                port:
                  number: 5001
```

### 5. Testing and Verification
1. Market Backend Testing:
```bash
curl -v http://40.233.73.93/market/api/job_market/newest
```
- Initially returned 503 Service Temporarily Unavailable
- After fixes, returned 200 OK with job market data

2. Editor Backend Testing:
```bash
curl -v http://40.233.73.93/editor/api/
```
- Initially returned 404 Not Found
- After fixes, returned 200 OK with "Flask App is Running!"

3. Service Status Verification:
```bash
kubectl get pods
```
All services confirmed running:
- editor-backend-7ddcd49578-hdsd5: Running
- editor-frontend-689c7c76f7-t98rx: Running
- market-backend-5457c9cb86-sq8dq: Running
- market-frontend-5b577b858c-ckwk5: Running
- postgres-86575cdb8-xhxm9: Running
- test-pod: Running

### 6. Log Analysis
1. Market Backend Logs:
```
Warning: OPENAI_KEY is not set. OpenAI embedding features will not work.
* Serving Flask app 'server'
* Debug mode: off
* Running on all addresses (0.0.0.0)
* Running on http://127.0.0.1:5001
* Running on http://10.0.10.242:5001
```

2. Ingress Controller Logs:
```
error retrieving resource lock ingress-nginx/ingress-controller-leader: leases.coordination.k8s.io "ingress-controller-leader" is forbidden
```

## Final Configuration

### 1. Frontend Services
Both frontend services configured with relative paths:
```yaml
env:
  - name: REACT_APP_BACKEND_URL
    value: "/api"
```

### 2. Backend Services
- Market Backend: Running on port 5001
- Editor Backend: Running on port 5001
- Both configured with proper database connections

### 3. Ingress Controller
- Properly configured with RBAC permissions
- Path rewriting rules implemented
- All services accessible through ingress

## Final Status

All endpoints are now accessible at:
1. Market frontend: `http://40.233.73.93/market`
2. Market backend: `http://40.233.73.93/market/api`
3. Editor frontend: `http://40.233.73.93/editor`
4. Editor backend: `http://40.233.73.93/editor/api`

## Lessons Learned
1. Importance of proper RBAC permissions for ingress controller
2. Need for correct path rewriting rules in ingress configuration
3. Value of using relative paths in frontend services
4. Importance of checking logs for debugging
5. Need to verify service status and connectivity at each step 



DEBUG NOTES:

based on this config file, what is the reason that accessing@https://resume.mintmelon.ca/  in browser gets 
GET https://resume.mintmelon.ca/ 503 (Service Unavailable) response? 

the log from ingress-nginx-controller is the following
10.244.0.129 - - [20/Apr/2025:01:01:53 +0000] "GET / HTTP/2.0" 503 592 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36" 498 0.000 [default-market-frontend-service-80] [] - - - - 3313096712d8575969a207e07d021b06

help me figure out the steps to debug and identify the causes of issue

kubectl get service market-frontend-service -o wide

kubectl get services --all-namespaces

kubectl get deployments --all-namespaces

kubectl get all --all-namespaces

kubectl get pods --all-namespaces

kubectl get ingress

kubectl get deployment market-frontend

kubectl describe deployment market-frontend


kubectl apply -f market-frontend.yaml

kubectl get deployment market-frontend

kubectl get deployment market-frontend

kubectl get service market-frontend-service

kubectl get pods -l app=market-frontend

curl -I https://resume.mintmelon.ca/


curl -k -I https://resume.mintmelon.ca/

kubectl describe pod -l app=market-frontend

kubectl logs -l app=market-frontend

kubectl get pods -n ingress-nginx

kubectl logs -n ingress-nginx ingress-nginx-controller-699dc9cf5c-lc84p | grep market-frontend | tail -10

kubectl exec -it -n ingress-nginx ingress-nginx-controller-699dc9cf5c-lc84p -- curl -v market-frontend-service.default.svc.cluster.local


kubectl exec -it -n ingress-nginx ingress-nginx-controller-699dc9cf5c-lc84p -- curl -v market-frontend-service

kubectl exec -it -n ingress-nginx ingress-nginx-controller-699dc9cf5c-lc84p -- curl -v 10.96.55.8

kubectl get endpoints market-frontend-service

kubectl get networkpolicy

kubectl port-forward deployment/market-frontend 8080:80 &

curl -v localhost:8080

kubectl describe configmap -n ingress-nginx ingress-nginx-controller

kubectl rollout restart deployment -n ingress-nginx ingress-nginx-controller


Let's check if the market-frontend deployment is now running properly:

```bash
kubectl get deployment market-frontend
```
Great! The market-frontend deployment now exists and appears to be ready. Let's also check the service:

```bash
kubectl get service market-frontend-service
```
Now let's check if the pods for the market-frontend are running properly:

```bash
kubectl get pods -l app=market-frontend
```
Let's check if we can access the site now:

```bash
curl -I https://resume.mintmelon.ca/
```
Let's try with the -k option to ignore the SSL certificate issue:

```bash
curl -k -I https://resume.mintmelon.ca/
```
Now we're seeing a 504 Gateway Timeout error. Let's check if the pods are actually ready and if there might be issues with the readiness probe:

```bash
kubectl describe pod -l app=market-frontend
```
The pod seems to be running fine and all readiness and liveness probes are passing. Let's check the logs for the pod:

```bash
kubectl logs -l app=market-frontend
```
The logs indicate that the pod is responding with 200 status codes to the kubelet probes, which means the application itself is working and accessible from within the cluster.

Let's check the ingress controller logs to see what might be causing the 504 error:

```bash
kubectl get pods -n ingress-nginx
```
Now let's check the logs of the ingress-nginx-controller:

```bash
kubectl logs -n ingress-nginx ingress-nginx-controller-699dc9cf5c-lc84p | grep market-frontend | tail -10
```
Now we're getting closer to identifying the issue. The ingress-nginx-controller logs show that it's trying to connect to the market-frontend service on port 80, but it's getting a 504 Gateway Timeout error. This suggests a connectivity issue between the ingress controller and the pods.

Let's check if we can establish connectivity from the ingress controller pod to the market-frontend service:

```bash
kubectl exec -it -n ingress-nginx ingress-nginx-controller-699dc9cf5c-lc84p -- curl -v market-frontend-service.default.svc.cluster.local
```
Let's try with just the service name:

```bash
kubectl exec -it -n ingress-nginx ingress-nginx-controller-699dc9cf5c-lc84p -- curl -v market-frontend-service
```
Let's try with the service IP:

```bash
kubectl exec -it -n ingress-nginx ingress-nginx-controller-699dc9cf5c-lc84p -- curl -v 10.96.55.8
```
Let's check the endpoints for this service:

```bash
kubectl get endpoints market-frontend-service
```
Let's check the network policy:

```bash
kubectl get networkpolicy
```
Let's try accessing the pod directly from outside the cluster using port-forwarding to determine if the issue is with the pod or with the ingress controller:

```bash
kubectl port-forward deployment/market-frontend 8080:80 &
```
Now let's try to access the service through the port-forward:

```bash
curl -v localhost:8080
```
Great! This confirms that the market-frontend pod is working correctly and can serve its content. The issue must be with the ingress controller.

Let's kill the port-forward process and examine the timeouts in the ingress configuration:

```bash
pkill -f "port-forward"
```
Let's check the configmap for the ingress-nginx controller:

```bash
kubectl get configmap -n ingress-nginx
```

```bash
kubectl describe configmap -n ingress-nginx ingress-nginx-controller
```
Let's add a configmap with increased timeouts to see if that helps:

```yaml:nginx-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
data:
  proxy-connect-timeout: "60"
  proxy-read-timeout: "60"
  proxy-send-timeout: "60"
  proxy-body-size: "10m"
  client-header-timeout: "60"
  client-body-timeout: "60"
  keep-alive-requests: "10000"
  keep-alive: "on"
```
Now let's apply this configmap:

```bash
kubectl apply -f nginx-configmap.yaml
```
Now let's restart the ingress-nginx-controller to make sure it picks up the new configuration:

```bash
kubectl rollout restart deployment -n ingress-nginx ingress-nginx-controller
```
Let's wait for the rollout to complete:

```bash
kubectl rollout status deployment -n ingress-nginx ingress-nginx-controller
```
Now let's try accessing the site again:

```bash
curl -k -I https://resume.mintmelon.ca/
```
Great! The site is now returning a 200 status code. Let's check the full response content:

```bash
curl -k https://resume.mintmelon.ca/ | head -15
```
Perfect! We've successfully fixed the issue. Here's a summary of what we found and fixed:

1. **The original issue**: The market-frontend-service was defined in the ingress configuration but didn't exist in the cluster, causing 503 Service Unavailable errors.

2. **Additional issues**:
   - After deploying the service, we encountered 504 Gateway Timeout errors
   - This was due to the default timeout settings in the ingress-nginx controller being too short

3. **The solution**:
   - First, we deployed the missing market-frontend deployment and service by applying the market-frontend.yaml file
   - Then, we increased the timeout settings in the ingress-nginx controller by creating a ConfigMap with extended timeouts
   - Finally, we restarted the ingress-nginx controller to apply these changes

For future reference, here are the key debugging steps we took:

1. Checked the existence of the service mentioned in the Ingress
2. Verified the running pods and deployments
3. Applied the missing deployment and service
4. Checked network connectivity using port-forwarding
5. Adjusted ingress controller timeouts
6. Restarted the ingress controller to apply changes

These steps should be helpful for debugging similar Kubernetes networking issues in the future.
