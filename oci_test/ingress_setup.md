# Ingress Setup and Troubleshooting

## Overview
This document outlines the steps taken to set up and troubleshoot the Nginx Ingress Controller for the resume editor application. The setup includes both market and editor frontends and backends.

## Initial Configuration

### 1. Ingress Class Configuration
Created `ingress-class.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
```

### 2. RBAC Configuration
Created `ingress-rbac.yaml` with necessary permissions:
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

### 3. Frontend Configuration
Both frontend services are configured to use relative paths for API calls:

#### Market Frontend (`market-frontend.yaml`):
```yaml
env:
  - name: REACT_APP_BACKEND_URL
    value: "/api"
```

#### Editor Frontend (`editor-frontend.yaml`):
```yaml
env:
  - name: REACT_APP_BACKEND_URL
    value: "/api"
```

### 4. Ingress Configuration
Final ingress configuration (`ingress.yaml`):
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

## Troubleshooting Steps

### 1. Permission Issues
- Added missing RBAC permissions for:
  - `coordination.k8s.io` leases
  - `discovery.k8s.io` endpointslices
  - `namespaces` resource

### 2. Path Rewriting
- Initially had issues with path rewriting
- Updated rewrite rules to properly handle both `/market/api` and `/editor/api` prefixes
- Final configuration strips the prefix and forwards the request to the appropriate backend

### 3. Service Configuration
- Verified all services are running and accessible
- Confirmed correct port mappings for all services
- Ensured frontend services use relative paths for API calls

## Final Status

All endpoints are now accessible at:
1. Market frontend: `http://40.233.73.93/market`
2. Market backend: `http://40.233.73.93/market/api`
3. Editor frontend: `http://40.233.73.93/editor`
4. Editor backend: `http://40.233.73.93/editor/api`

### Verification
- Market backend API endpoint `/market/api/job_market/newest` returns 200 OK
- Editor backend root endpoint `/editor/api/` returns "Flask App is Running!"
- All services are properly routed through the ingress controller 