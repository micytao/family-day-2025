#!/bin/bash

# Deploy Family Day 2025 to OpenShift with vLLM
# This script automates the deployment process using container image

set -e

# Configuration
NAMESPACE="${NAMESPACE:-family-day}"
VLLM_NAMESPACE="${VLLM_NAMESPACE:-rhaiis}"
VLLM_SERVICE="${VLLM_SERVICE:-rhaiis-service}"
VLLM_PORT="${VLLM_PORT:-8000}"
CONTAINER_IMAGE="${CONTAINER_IMAGE:-quay.io/rh_ee_micyang/family-day-web-prod:0.1}"

echo "================================================"
echo "Family Day 2025 - OpenShift Deployment"
echo "================================================"
echo ""
echo "Configuration:"
echo "  App Namespace:    $NAMESPACE"
echo "  Container Image:  $CONTAINER_IMAGE"
echo "  vLLM Namespace:   $VLLM_NAMESPACE"
echo "  vLLM Service:     $VLLM_SERVICE"
echo "  vLLM Port:        $VLLM_PORT"
echo "  Model:            Qwen/Qwen2-VL-2B-Instruct"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v oc &> /dev/null; then
    echo "❌ Error: 'oc' CLI not found. Please install OpenShift CLI."
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: 'kubectl' CLI not found. Please install kubectl."
    exit 1
fi

echo "✅ CLI tools found"

# Check if logged into OpenShift
if ! oc whoami &> /dev/null; then
    echo "❌ Error: Not logged into OpenShift cluster."
    echo "   Please run: oc login <cluster-url>"
    exit 1
fi

echo "✅ Logged into OpenShift as: $(oc whoami)"

# Verify vLLM service exists
echo ""
echo "Verifying vLLM service..."
if ! kubectl get svc $VLLM_SERVICE -n $VLLM_NAMESPACE &> /dev/null; then
    echo "⚠️  Warning: vLLM service '$VLLM_SERVICE' not found in namespace '$VLLM_NAMESPACE'"
    echo "   Make sure vLLM is deployed before proceeding."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ vLLM service found: $VLLM_SERVICE.$VLLM_NAMESPACE"
fi

# Create namespace
echo ""
echo "Creating namespace '$NAMESPACE'..."
oc create namespace $NAMESPACE 2>/dev/null || echo "  Namespace already exists"

# Deploy application using container image
echo ""
echo "Deploying application from container image..."
echo "Image: $CONTAINER_IMAGE"
cat <<EOF | oc apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: family-day-app
  namespace: $NAMESPACE
  labels:
    app: family-day
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
        image: $CONTAINER_IMAGE
        imagePullPolicy: Always
        ports:
        - containerPort: 8000
          name: http
          protocol: TCP
        env:
        - name: VLLM_NAMESPACE
          value: "$VLLM_NAMESPACE"
        - name: VLLM_SERVICE
          value: "$VLLM_SERVICE"
        - name: VLLM_PORT
          value: "$VLLM_PORT"
        resources:
          limits:
            cpu: "500m"
            memory: "256Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: family-day-service
  namespace: $NAMESPACE
  labels:
    app: family-day
spec:
  selector:
    app: family-day
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
    name: http
  type: ClusterIP
EOF

echo "✅ Deployment created"

# Create route
echo ""
echo "Creating route..."
oc create route edge family-day-route \
  --service=family-day-service \
  --port=8000 \
  --namespace=$NAMESPACE \
  --insecure-policy=Redirect \
  2>/dev/null || echo "  Route already exists, updating..."

oc patch route family-day-route -n $NAMESPACE -p '{"spec":{"port":{"targetPort":"http"},"tls":{"termination":"edge","insecureEdgeTerminationPolicy":"Redirect"}}}'

echo "✅ Route created"

# Wait for deployment
echo ""
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=120s deployment/family-day-app -n $NAMESPACE

# Force rollout to pull latest image
echo ""
echo "Forcing rollout to pull latest image..."
oc rollout restart deployment/family-day-app -n $NAMESPACE
sleep 5
kubectl wait --for=condition=available --timeout=120s deployment/family-day-app -n $NAMESPACE

# Get route URL
echo ""
echo "================================================"
echo "Deployment Successful! 🎉"
echo "================================================"
echo ""
ROUTE_URL=$(oc get route family-day-route -n $NAMESPACE -o jsonpath='{.spec.host}')
echo "Application URL: https://$ROUTE_URL"
echo ""
echo "Next Steps:"
echo "1. Open the URL in your browser"
echo "2. Allow camera access when prompted"
echo "3. Click 'OpenShift Proxy' button"
echo "4. Click 'Test vLLM (Advanced)' to verify connection"
echo "5. Start playing the Vision Quest game!"
echo ""
echo "Troubleshooting:"
echo "  View logs:  oc logs -f deployment/family-day-app -n $NAMESPACE"
echo "  Check pods: oc get pods -n $NAMESPACE"
echo "  Describe:   oc describe deployment family-day-app -n $NAMESPACE"
echo ""

# Optional: Open in browser
if command -v xdg-open &> /dev/null; then
    read -p "Open in browser? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open "https://$ROUTE_URL"
    fi
elif command -v open &> /dev/null; then
    read -p "Open in browser? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "https://$ROUTE_URL"
    fi
fi

echo "Deployment complete! ✅"

