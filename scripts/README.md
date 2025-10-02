# 🔧 Scripts

This folder contains automation scripts for building and deploying the AI Vision Quest game.

## Files

### Container Management
- **build-container.sh** - 🏗️ Build and push container image to Quay.io

### Deployment
- **deploy-to-openshift.sh** - 🚀 Deploy the game to OpenShift

## Usage

### Build Container
```bash
./scripts/build-container.sh
```

### Deploy to OpenShift
```bash
./scripts/deploy-to-openshift.sh
```

## Prerequisites

- Podman or Docker installed
- Quay.io credentials configured
- OpenShift CLI (oc) installed and logged in
- Appropriate cluster permissions

## Configuration

All scripts use the container image:
- Registry: `quay.io`
- Repository: `rh_ee_micyang/family-day-web-prod`
- Tag: `0.1` (update as needed)

See [../docs/PRODUCTION_DEPLOYMENT.md](../docs/PRODUCTION_DEPLOYMENT.md) for detailed deployment instructions.

