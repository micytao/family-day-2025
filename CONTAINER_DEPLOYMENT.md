# Container Deployment Guide

## Container Image

**Image:** `quay.io/rh_ee_micyang/family-day-web-prod:0.1`

This container includes:
- Production HTML web application (`prod-index.html`)
- Nginx web server with vLLM proxy configuration
- Configured for Qwen/Qwen2-VL-2B-Instruct model (2B parameters, excellent for real-time games)
- Health check endpoint at `/health`
- Runs on port 8000
- OpenShift-compatible (non-root user, UID 101)

## Quick Start

### 1. Build the Container

```bash
./build-container.sh
```

This will build and tag the image as `quay.io/rh_ee_micyang/family-day-web-prod:0.1`.

### 2. Test Locally

```bash
# Run with podman
podman run -d -p 8000:8000 --name family-day \
  quay.io/rh_ee_micyang/family-day-web-prod:0.1

# Or with docker
docker run -d -p 8000:8000 --name family-day \
  quay.io/rh_ee_micyang/family-day-web-prod:0.1

# Access at http://localhost:8000
```

### 3. Push to Registry

```bash
# Login to Quay.io
podman login quay.io

# Push the image
podman push quay.io/rh_ee_micyang/family-day-web-prod:0.1
```

### 4. Deploy to OpenShift

```bash
# Automated deployment (recommended)
./deploy-to-openshift.sh

# Or manual deployment
oc new-project family-day
oc new-app quay.io/rh_ee_micyang/family-day-web-prod:0.1 \
  --name=family-day-app \
  -e VLLM_NAMESPACE=rhaiis \
  -e VLLM_SERVICE=rhaiis-service \
  -e VLLM_PORT=8000
oc expose svc/family-day-app
```

## Container Architecture

### Base Image
- **Base:** `nginx:1.25-alpine`
- **User:** UID 101 (nginx user)
- **Port:** 8000

### Directory Structure
```
/app/web/
  └── index.html (from prod-index.html)

/etc/nginx/
  └── nginx.conf (custom configuration)

/tmp/nginx/
  └── (nginx runtime directories)
```

### Nginx Configuration

The container includes a built-in nginx configuration that:

1. **Serves the web application** at `/`
   - Location: `/app/web/index.html`
   - Supports static assets

2. **Proxies vLLM API requests** at `/v1/*`
   - Target: `http://rhaiis-service.rhaiis.svc.cluster.local:8000`
   - Includes CORS headers
   - Handles preflight OPTIONS requests
   - Configurable via environment variables

3. **Health check endpoint** at `/health`
   - Returns 200 OK with "healthy" message

### Environment Variables

Configure the vLLM backend connection:

| Variable | Default | Description |
|----------|---------|-------------|
| `VLLM_NAMESPACE` | `rhaiis` | Kubernetes namespace where vLLM is running |
| `VLLM_SERVICE` | `rhaiis-service` | Service name of the vLLM instance |
| `VLLM_PORT` | `8000` | Port where vLLM is listening |

**Note:** The current Containerfile has the vLLM proxy URL hardcoded. To use environment variables at runtime, you'll need to use a template-based approach or entrypoint script.

## Deployment Options

### Option 1: Automated Script (Recommended)

```bash
# With defaults
./deploy-to-openshift.sh

# With custom configuration
export NAMESPACE="family-day"
export VLLM_NAMESPACE="rhaiis"
export VLLM_SERVICE="rhaiis-service"
export CONTAINER_IMAGE="quay.io/rh_ee_micyang/family-day-web-prod:0.1"
./deploy-to-openshift.sh
```

### Option 2: Using oc new-app

```bash
oc new-project family-day

oc new-app quay.io/rh_ee_micyang/family-day-web-prod:0.1 \
  --name=family-day-app

oc expose svc/family-day-app

oc get route family-day-app
```

### Option 3: Manual YAML Deployment

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
  namespace: family-day
spec:
  selector:
    app: family-day
  ports:
  - port: 8000
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
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
    targetPort: 8000
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

## Health Checks

The container includes a health endpoint:

```bash
# Test locally
curl http://localhost:8000/health

# Expected response: 200 OK
# Body: healthy
```

## Troubleshooting

### Container won't start

```bash
# Check logs
podman logs family-day

# Check if port 8000 is already in use
lsof -i :8000
```

### Application not accessible

```bash
# Check if container is running
podman ps

# Check container health
curl http://localhost:8000/health

# Check nginx error logs
podman exec -it family-day cat /var/log/nginx/error.log
```

### vLLM connection fails

The container's nginx is configured to proxy to:
```
http://rhaiis-service.rhaiis.svc.cluster.local:8000
```

To change this, you need to:
1. Update the Containerfile nginx configuration
2. Rebuild the container
3. Push and redeploy

Or use the ConfigMap-based deployment from `PRODUCTION_DEPLOYMENT.md`.

### OpenShift deployment issues

```bash
# Check pod status
oc get pods -n family-day

# Check pod logs
oc logs -f deployment/family-day-app -n family-day

# Check events
oc get events -n family-day --sort-by='.lastTimestamp'

# Describe the deployment
oc describe deployment family-day-app -n family-day
```

## Image Registry

### Public vs Private

The image is hosted on **Quay.io** under:
- Registry: `quay.io`
- Namespace: `rh_ee_micyang`
- Repository: `family-day-web-prod`
- Tag: `0.1`

### Making it Public

To make the image publicly accessible:

1. Go to https://quay.io/repository/rh_ee_micyang/family-day-web-prod
2. Click Settings → Repository Visibility
3. Change to "Public"

### Using Private Images in OpenShift

If the image is private:

```bash
# Create a pull secret
oc create secret docker-registry quay-secret \
  --docker-server=quay.io \
  --docker-username=<username> \
  --docker-password=<password> \
  --docker-email=<email> \
  -n family-day

# Link the secret to the default service account
oc secrets link default quay-secret --for=pull -n family-day

# Then deploy
oc new-app quay.io/rh_ee_micyang/family-day-web-prod:0.1
```

## Updating the Container

### Making Changes

1. Modify `prod-index.html` or `Containerfile`
2. Rebuild the container:
   ```bash
   ./build-container.sh
   ```
3. Push to registry:
   ```bash
   podman push quay.io/rh_ee_micyang/family-day-web-prod:0.1
   ```
4. Update the deployment:
   ```bash
   oc rollout restart deployment/family-day-app -n family-day
   ```

### Versioning

Consider using semantic versioning for production:

```bash
# Build with specific version
podman build -t quay.io/rh_ee_micyang/family-day-web-prod:0.2 -f Containerfile .

# Also tag as latest
podman tag quay.io/rh_ee_micyang/family-day-web-prod:0.2 \
  quay.io/rh_ee_micyang/family-day-web-prod:latest

# Push both
podman push quay.io/rh_ee_micyang/family-day-web-prod:0.2
podman push quay.io/rh_ee_micyang/family-day-web-prod:latest
```

## Security Considerations

### Non-Root User

The container runs as UID 101 (nginx user) for security:
- OpenShift compatible
- Follows security best practices
- Can't bind to ports < 1024 (uses 8000 instead)

### Image Scanning

Scan the image for vulnerabilities:

```bash
# Using podman
podman scan quay.io/rh_ee_micyang/family-day-web-prod:0.1

# Using trivy
trivy image quay.io/rh_ee_micyang/family-day-web-prod:0.1
```

### CORS Configuration

The nginx configuration allows all origins (`*`) for development.

For production, update the Containerfile to restrict CORS:

```nginx
# Instead of:
add_header 'Access-Control-Allow-Origin' '*' always;

# Use:
add_header 'Access-Control-Allow-Origin' 'https://your-domain.com' always;
```

## Performance Tuning

### Resource Limits

Adjust based on your needs:

```yaml
resources:
  limits:
    cpu: "1"
    memory: "512Mi"
  requests:
    cpu: "200m"
    memory: "256Mi"
```

### Scaling

The web frontend can be scaled horizontally:

```bash
oc scale deployment/family-day-app --replicas=3 -n family-day
```

### Caching

The nginx configuration includes caching for static assets:
- Cache duration: 1 year
- Asset types: js, css, png, jpg, jpeg, gif, ico, svg, fonts

## Files Reference

- **Containerfile** - Container build definition
- **build-container.sh** - Build and push script
- **deploy-to-openshift.sh** - Automated OpenShift deployment
- **prod-index.html** - Production web application
- **PRODUCTION_DEPLOYMENT.md** - Detailed deployment guide
- **PRODUCTION_README.md** - Quick start guide
- **CONTAINER_DEPLOYMENT.md** - This file

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review nginx logs in the container
3. Check OpenShift pod events and logs
4. Verify vLLM service is running and accessible
5. Test the `/health` endpoint

---

**Ready to deploy? Run:**

```bash
./build-container.sh
podman push quay.io/rh_ee_micyang/family-day-web-prod:0.1
./deploy-to-openshift.sh
```

🚀 Happy deploying!

