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