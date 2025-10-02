# ⚙️ Configuration Files

This folder contains configuration files for containerization and deployment.

## Files

### Container Configuration
- **Containerfile** - 🐳 Container image definition (Dockerfile format)

### Kubernetes/OpenShift Deployment
- **rhaiis-deployment.yml** - ☸️ Kubernetes deployment manifest for the game

## Containerfile

Defines how to build the container image:
- Base: NGINX
- Copies HTML files
- Exposes port 8080
- Optimized for OpenShift

## rhaiis-deployment.yml

Kubernetes manifest that includes:
- Deployment configuration
- Service definition
- Resource limits
- Health checks
- Environment variables for AI endpoint

## Usage

### Build Container
```bash
podman build -f config/Containerfile -t family-day-web:latest .
```

### Deploy to OpenShift
```bash
oc apply -f config/rhaiis-deployment.yml
```

See [../docs/CONTAINER_DEPLOYMENT.md](../docs/CONTAINER_DEPLOYMENT.md) for complete instructions.

