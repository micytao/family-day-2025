#!/bin/bash
# Build script for Red Hat Family Day 2025 container

set -e

# Container image configuration
REGISTRY="quay.io"
USERNAME="rh_ee_micyang"
IMAGE_NAME="family-day-web-prod"
IMAGE_TAG="0.1"
FULL_IMAGE="${REGISTRY}/${USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "🎩 Building Red Hat Family Day 2025 Container..."
echo "================================================"
echo "Image: ${FULL_IMAGE}"
echo ""

# Build the container using podman (or docker)
if command -v podman &> /dev/null; then
    echo "Using podman to build..."
    podman build -t ${FULL_IMAGE} -f config/Containerfile .
    echo ""
    echo "✅ Container built successfully!"
    echo ""
    echo "📦 To run locally:"
    echo "   podman run -d -p 8000:8000 --name family-day ${FULL_IMAGE}"
    echo ""
    echo "🌐 Access the app at: http://localhost:8000"
    echo ""
    echo "🚀 To push to registry:"
    echo "   podman login ${REGISTRY}"
    echo "   podman push ${FULL_IMAGE}"
    echo ""
    echo "📋 To deploy on OpenShift:"
    echo "   oc new-app ${FULL_IMAGE}"
    echo "   oc expose svc/family-day-web-prod"
elif command -v docker &> /dev/null; then
    echo "Using docker to build..."
    docker build -t ${FULL_IMAGE} -f config/Containerfile .
    echo ""
    echo "✅ Container built successfully!"
    echo ""
    echo "📦 To run locally:"
    echo "   docker run -d -p 8000:8000 --name family-day ${FULL_IMAGE}"
    echo ""
    echo "🌐 Access the app at: http://localhost:8000"
    echo ""
    echo "🚀 To push to registry:"
    echo "   docker login ${REGISTRY}"
    echo "   docker push ${FULL_IMAGE}"
    echo ""
    echo "📋 To deploy on OpenShift:"
    echo "   oc new-app ${FULL_IMAGE}"
    echo "   oc expose svc/family-day-web-prod"
else
    echo "❌ Error: Neither podman nor docker found!"
    echo "Please install podman or docker to build the container."
    exit 1
fi

