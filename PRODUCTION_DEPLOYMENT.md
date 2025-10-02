# Production Deployment Guide - OpenShift with vLLM

## Overview
This guide explains how to deploy the Family Day 2025 AI Vision Quest application on OpenShift with Red Hat AI Inference Server (vLLM) running in a separate namespace.

## Architecture

```
┌─────────────────────────────────────┐
│   OpenShift Cluster                 │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Namespace: family-day       │  │
│  │                              │  │
│  │  - Web App (prod-index.html) │  │
│  │  - Route/Ingress             │  │
│  │  - Nginx/Service Mesh        │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│             │ Proxy /v1/*           │
│             ↓                       │
│  ┌──────────────────────────────┐  │
│  │  Namespace: vllm-inference   │  │
│  │                              │  │
│  │  - vLLM Server (port 8000)   │  │
│  │  - Vision-Language Model     │  │
│  └──────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

## Prerequisites

1. **OpenShift Cluster** with admin access
2. **Red Hat AI Inference Server (vLLM)** deployed and running
3. **Vision-Language Model** loaded in vLLM: **Qwen/Qwen2-VL-2B-Instruct**
4. Cross-namespace networking enabled

## Step 1: Verify vLLM Setup

First, ensure vLLM is running correctly:

```bash
# Check vLLM pods
kubectl get pods -n <vllm-namespace>

# Check vLLM service
kubectl get svc -n <vllm-namespace>

# Expected output should show vLLM service on port 8000
# NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
# vllm-service  ClusterIP   10.x.x.x        <none>        8000/TCP   Xd
```

Test vLLM locally within the cluster:

```bash
# Port-forward to test
kubectl port-forward -n <vllm-namespace> svc/vllm-service 8000:8000

# In another terminal, test endpoints
curl http://localhost:8000/v1/models
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "your-model-name",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

## Step 2: Deploy Web Application

### Option A: Using Pre-Built Container Image (Recommended)

Deploy using the pre-built container image with nginx and vLLM proxy configuration:

```bash
# Set your configuration
export NAMESPACE="family-day"
export VLLM_NAMESPACE="rhaiis"
export VLLM_SERVICE="rhaiis-service"
export CONTAINER_IMAGE="quay.io/rh_ee_micyang/family-day-web-prod:0.1"

# Run the deployment script
./deploy-to-openshift.sh
```

Or deploy manually:

```bash
oc new-project family-day

# Deploy the container
oc new-app quay.io/rh_ee_micyang/family-day-web-prod:0.1 \
  --name=family-day-app \
  -e VLLM_NAMESPACE=rhaiis \
  -e VLLM_SERVICE=rhaiis-service \
  -e VLLM_PORT=8000

# Expose the service
oc expose svc/family-day-app

# Get the route
oc get route family-day-app
```

### Option B: Using nginx ConfigMap

Alternatively, create an nginx configuration that proxies requests:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: family-day
data:
  nginx.conf: |
    events {}
    http {
        server {
            listen 8080;
            
            # Serve static files
            location / {
                root /usr/share/nginx/html;
                index prod-index.html;
                try_files $uri $uri/ /prod-index.html;
            }
            
            # Proxy /v1/* to vLLM service in another namespace
            location /v1/ {
                proxy_pass http://vllm-service.<vllm-namespace>.svc.cluster.local:8000;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                
                # CORS headers
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
                add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
                
                # Handle preflight
                if ($request_method = 'OPTIONS') {
                    add_header 'Access-Control-Max-Age' 1728000;
                    add_header 'Content-Type' 'text/plain; charset=utf-8';
                    add_header 'Content-Length' 0;
                    return 204;
                }
            }
        }
    }
```

### Option C: Custom Deployment YAML

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: family-day-app
  namespace: family-day
spec:
  replicas: 1
  selector:
    matchLabels:
      app: family-day
  template:
    metadata:
      labels:
        app: family-day
    spec:
      containers:
      - name: web
        image: quay.io/rh_ee_micyang/family-day-web-prod:0.1
        ports:
        - containerPort: 8000
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      volumes:
      - name: html
        configMap:
          name: family-day-html
      - name: nginx-config
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: family-day-html
  namespace: family-day
data:
  prod-index.html: |
    # Paste content of prod-index.html here
---
apiVersion: v1
kind: Service
metadata:
  name: family-day-service
  namespace: family-day
spec:
  selector:
    app: family-day
  ports:
  - port: 8080
    targetPort: 8080
---
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: family-day-route
  namespace: family-day
spec:
  to:
    kind: Service
    name: family-day-service
  port:
    targetPort: 8080
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

### Quick Deploy Script

The easiest way to deploy is using the provided script:

```bash
#!/bin/bash

# Simply run the deployment script
./deploy-to-openshift.sh

# Or with custom configuration:
export NAMESPACE="family-day"
export VLLM_NAMESPACE="rhaiis"
export VLLM_SERVICE="rhaiis-service"
export CONTAINER_IMAGE="quay.io/rh_ee_micyang/family-day-web-prod:0.1"
./deploy-to-openshift.sh
```

**Manual deployment alternative:**

```bash
#!/bin/bash

NAMESPACE="family-day"
VLLM_NAMESPACE="rhaiis"
VLLM_SERVICE="rhaiis-service"
CONTAINER_IMAGE="quay.io/rh_ee_micyang/family-day-web-prod:0.1"

# Create namespace
oc create namespace $NAMESPACE || true

# Create nginx config
cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: $NAMESPACE
data:
  nginx.conf: |
    events {}
    http {
        include /etc/nginx/mime.types;
        default_type application/octet-stream;
        
        server {
            listen 8080;
            
            location / {
                root /usr/share/nginx/html;
                index prod-index.html;
                try_files \$uri \$uri/ /prod-index.html;
            }
            
            location /v1/ {
                proxy_pass http://$VLLM_SERVICE.$VLLM_NAMESPACE.svc.cluster.local:8000;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_buffering off;
                proxy_read_timeout 300s;
                
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
                add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization';
                
                if (\$request_method = 'OPTIONS') {
                    add_header 'Access-Control-Max-Age' 1728000;
                    add_header 'Content-Type' 'text/plain; charset=utf-8';
                    add_header 'Content-Length' 0;
                    return 204;
                }
            }
        }
    }
EOF

# Deploy application
oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: family-day-app
  namespace: $NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: family-day
  template:
    metadata:
      labels:
        app: family-day
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
        - name: nginx-config
          mountPath: /etc/nginx/nginx.conf
          subPath: nginx.conf
      volumes:
      - name: html
        configMap:
          name: family-day-html
      - name: nginx-config
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: Service
metadata:
  name: family-day-service
  namespace: $NAMESPACE
spec:
  selector:
    app: family-day
  ports:
  - port: 8080
    targetPort: 8080
EOF

# Create route
oc expose svc/family-day-service -n $NAMESPACE || true

# Get route URL
echo "Deployment complete!"
echo "Access your app at:"
oc get route family-day-service -n $NAMESPACE -o jsonpath='{.spec.host}'
echo ""
```

## Step 3: Configure Network Policies (if needed)

If your cluster uses NetworkPolicies, ensure cross-namespace communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-family-day
  namespace: <vllm-namespace>
spec:
  podSelector:
    matchLabels:
      app: vllm
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: family-day
    ports:
    - protocol: TCP
      port: 8000
```

## Step 4: Test the Deployment

1. **Access the application** via the route URL
2. **Click "OpenShift Proxy"** button to use relative path
3. **Click "Test vLLM (Advanced)"** to verify connectivity
4. You should see:
   - ✅ Models endpoint OK
   - ✅ Chat completions endpoint OK
   - 🎉 vLLM is ready! All tests passed.

## Troubleshooting

### vLLM Connection Fails

```bash
# Check if vLLM service is accessible from web app pod
POD=$(kubectl get pod -n family-day -l app=family-day -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -n family-day -- sh

# Inside pod, test connectivity
apk add curl
curl http://vllm-service.<vllm-namespace>.svc.cluster.local:8000/v1/models
```

### CORS Errors

Ensure nginx is properly proxying headers. Check nginx logs:

```bash
kubectl logs -n family-day -l app=family-day --tail=100 -f
```

### Cross-Namespace Communication Issues

Verify NetworkPolicies and service mesh configuration:

```bash
# Check if services can be resolved
kubectl run test-dns --image=busybox -n family-day --rm -it -- nslookup vllm-service.<vllm-namespace>.svc.cluster.local
```

## Performance Optimization

### For Large Models

If using large vision models, adjust timeouts:

```nginx
location /v1/ {
    proxy_read_timeout 600s;  # Increase for slow models
    proxy_send_timeout 600s;
    proxy_connect_timeout 60s;
}
```

### For High Traffic

Scale the web application:

```bash
oc scale deployment/family-day-app --replicas=3 -n family-day
```

## Security Considerations

1. **Use TLS/HTTPS** - Route should have TLS termination enabled
2. **Limit CORS** - In production, restrict `Access-Control-Allow-Origin` to your domain
3. **Add Authentication** - Consider adding OAuth/SSO if needed
4. **Resource Limits** - Set appropriate CPU/memory limits

```yaml
resources:
  limits:
    cpu: "1"
    memory: "512Mi"
  requests:
    cpu: "100m"
    memory: "128Mi"
```

## Monitoring

Set up monitoring to track:
- vLLM response times
- Request success/failure rates
- Web application health

```bash
# Check pod status
oc get pods -n family-day -w

# View logs
oc logs -f deployment/family-day-app -n family-day
```

## Updates and Maintenance

To update the application:

```bash
# Update HTML
oc create configmap family-day-html \
  --from-file=prod-index.html \
  -n family-day \
  --dry-run=client -o yaml | oc apply -f -

# Restart deployment
oc rollout restart deployment/family-day-app -n family-day
```

## Success Criteria

✅ Web application is accessible via HTTPS
✅ "Test vLLM (Advanced)" button shows all checks passing
✅ Camera access works in browser
✅ Vision quest challenges are processed successfully
✅ vLLM responds to image + text prompts

---

**Need Help?**
- Check vLLM logs: `kubectl logs -n <vllm-namespace> -l app=vllm`
- Check web app logs: `kubectl logs -n family-day -l app=family-day`
- Use browser DevTools to inspect network requests
- Test endpoints manually with curl/Postman

