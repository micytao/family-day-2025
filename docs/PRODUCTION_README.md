# Production Deployment - Quick Start Guide

## What You Have

✅ **prod-index.html** - Production-ready HTML with vLLM integration
✅ **deploy-to-openshift.sh** - Automated deployment script
✅ **PRODUCTION_DEPLOYMENT.md** - Detailed deployment guide
✅ **DEV_VS_PROD.md** - Comparison between dev and prod versions

## Key Features of Production Version

### 1. vLLM Integration
- Default endpoint: Empty (OpenShift proxy mode)
- Supports Red Hat AI Inference Server (vLLM) on port 8000
- Model: Qwen/Qwen2-VL-2B-Instruct (2B parameters, excellent instruction following)
- OpenAI-compatible API format

### 2. Test Functions
- **Test Connection** - Basic API connectivity check
- **Test vLLM (Advanced)** - Comprehensive vLLM validation
  - Tests `/v1/models` endpoint
  - Tests `/v1/chat/completions` endpoint
  - Provides detailed troubleshooting

### 3. Preset Endpoints
- vLLM:8000 (new!)
- OpenShift Proxy (new!)
- Ollama:11434
- llama.cpp:8080

### 4. Production-Ready
- Cross-namespace service communication
- CORS handling via nginx proxy
- TLS/HTTPS support
- Resource limits and health checks

## Quick Deploy (3 Steps)

### Step 1: Verify vLLM is Running

```bash
# Check vLLM service (Red Hat AI Inference Server)
export VLLM_NAMESPACE="rhaiis"
kubectl get pods -n $VLLM_NAMESPACE
kubectl get svc -n $VLLM_NAMESPACE

# Should show RHAIIS service on port 8000
```

### Step 2: Deploy the Application

The application is available as a pre-built container image: **`quay.io/rh_ee_micyang/family-day-web-prod:0.1`**

```bash
# Option 1: Use the automated deployment script (Recommended)
./deploy-to-openshift.sh

# Option 2: Deploy with custom configuration
export NAMESPACE="family-day"
export VLLM_NAMESPACE="rhaiis"
export VLLM_SERVICE="rhaiis-service"
export CONTAINER_IMAGE="quay.io/rh_ee_micyang/family-day-web-prod:0.1"
./deploy-to-openshift.sh

# Option 3: Quick deploy with oc
oc new-project family-day
oc new-app quay.io/rh_ee_micyang/family-day-web-prod:0.1 \
  --name=family-day-app \
  -e VLLM_NAMESPACE=rhaiis \
  -e VLLM_SERVICE=rhaiis-service \
  -e VLLM_PORT=8000
oc expose svc/family-day-app
```

### Step 3: Test and Verify

1. Open the application URL (shown at end of deployment)
2. Allow camera access
3. Click **"OpenShift Proxy"** button
4. Click **"Test vLLM (Advanced)"** button
5. Verify all checks pass ✅

## Expected Test Output

```
Testing vLLM API endpoints...

1️⃣ Testing /v1/models endpoint...
✅ Models endpoint OK
   Available models: Qwen/Qwen2-VL-2B-Instruct

2️⃣ Testing /v1/chat/completions endpoint...
✅ Chat completions endpoint OK
   Response: Hello! How can I help you?

🎉 vLLM is ready! All tests passed.
```

## Architecture

```
User Browser (HTTPS)
        ↓
OpenShift Route (TLS termination)
        ↓
Nginx Service (family-day namespace)
        ├─ / → prod-index.html
        └─ /v1/* → vLLM Service (port 8000)
                ↓
        vLLM Pod (vllm-inference namespace)
```

## Troubleshooting

### Issue: Connection Test Fails

**Check vLLM Service:**
```bash
kubectl get svc -n $VLLM_NAMESPACE
kubectl get pods -n $VLLM_NAMESPACE
kubectl logs -n $VLLM_NAMESPACE -l app=vllm
```

**Test from App Pod:**
```bash
POD=$(kubectl get pod -n family-day -l app=family-day -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -n family-day -- sh

# Inside pod
apk add curl
curl http://vllm-service.$VLLM_NAMESPACE.svc.cluster.local:8000/v1/models
```

### Issue: CORS Errors

**Check Nginx Config:**
```bash
kubectl get configmap nginx-config -n family-day -o yaml
```

**View Nginx Logs:**
```bash
kubectl logs -f -n family-day -l app=family-day
```

### Issue: Camera Not Working

- Ensure you're accessing via **HTTPS** (not HTTP)
- Check browser permissions
- Try different browser (Chrome, Firefox, Safari)

## Manual Deployment (Alternative)

If you prefer manual deployment, see **PRODUCTION_DEPLOYMENT.md** for:
- Detailed YAML configurations
- Step-by-step instructions
- NetworkPolicy setup
- Advanced configurations

## Configuration Options

### Custom vLLM Service

Edit `deploy-to-openshift.sh`:
```bash
VLLM_NAMESPACE="your-namespace"
VLLM_SERVICE="your-service-name"
VLLM_PORT="8000"
```

### Custom Nginx Configuration

Edit the ConfigMap in `deploy-to-openshift.sh` to:
- Change timeouts
- Add authentication
- Modify CORS settings
- Add rate limiting

### Resource Limits

Default limits in deployment:
```yaml
resources:
  limits:
    cpu: "500m"
    memory: "256Mi"
  requests:
    cpu: "100m"
    memory: "128Mi"
```

Adjust based on expected load.

## Scaling

### Scale Web Application

```bash
oc scale deployment/family-day-app --replicas=3 -n family-day
```

### vLLM Scaling

vLLM typically runs on GPU nodes and may not scale horizontally easily. Consider:
- Using larger GPU instances
- Implementing request queuing
- Load balancing across multiple vLLM instances

## Monitoring

### Check Application Status

```bash
# Pod status
oc get pods -n family-day

# View logs
oc logs -f deployment/family-day-app -n family-day

# Describe deployment
oc describe deployment family-day-app -n family-day
```

### Check vLLM Status

```bash
# vLLM pods
kubectl get pods -n $VLLM_NAMESPACE

# vLLM logs
kubectl logs -f -n $VLLM_NAMESPACE -l app=vllm
```

## Updates

### Update to New Container Version

```bash
# Build new container version
./build-container.sh

# Push to registry
podman push quay.io/rh_ee_micyang/family-day-web-prod:0.1

# Update deployment
oc set image deployment/family-day-app \
  web=quay.io/rh_ee_micyang/family-day-web-prod:0.1 \
  -n family-day

# Or restart the entire deployment
oc rollout restart deployment/family-day-app -n family-day
```

### Redeploy from Scratch

```bash
# Delete existing deployment
oc delete all -l app=family-day -n family-day

# Redeploy
./deploy-to-openshift.sh
```

## Security Best Practices

1. **Use HTTPS** - Always access via secure route ✅
2. **Restrict CORS** - In production, limit to your domain
3. **Add Authentication** - Consider OAuth/SSO for real deployment
4. **Network Policies** - Restrict traffic between namespaces
5. **Resource Limits** - Prevent resource exhaustion
6. **Regular Updates** - Keep nginx and base images updated

## Performance Tips

1. **Increase vLLM timeout** if using large models:
   ```nginx
   proxy_read_timeout 600s;
   ```

2. **Enable caching** for static assets:
   ```nginx
   location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
       expires 1d;
   }
   ```

3. **Scale horizontally** for high traffic:
   ```bash
   oc scale deployment/family-day-app --replicas=5
   ```

## Success Criteria Checklist

Before the Family Day event, verify:

- [ ] vLLM is running and healthy
- [ ] Web application is deployed
- [ ] HTTPS route is accessible
- [ ] Camera works in browser (HTTPS required)
- [ ] "Test vLLM (Advanced)" passes all checks
- [ ] Vision quest challenges work end-to-end
- [ ] Image upload and processing successful
- [ ] Response times are acceptable (< 10 seconds)
- [ ] Multiple concurrent users can connect
- [ ] Logs show no errors

## Getting Help

**Documentation Files:**
- `PRODUCTION_DEPLOYMENT.md` - Comprehensive deployment guide
- `DEV_VS_PROD.md` - Differences between versions
- `QUICK_START.md` - Original quick start (dev version)

**Useful Commands:**
```bash
# View all resources
oc get all -n family-day

# Check events
oc get events -n family-day --sort-by='.lastTimestamp'

# Port forward for testing
oc port-forward svc/family-day-service 8080:8080 -n family-day
```

**OpenShift Console:**
- Navigate to your project
- View Topology
- Check logs and metrics
- Monitor pod status

## Next Steps After Deployment

1. **Test thoroughly** with different browsers
2. **Run load tests** if expecting many users
3. **Set up monitoring** (Prometheus, Grafana)
4. **Configure backups** if needed
5. **Document any customizations**
6. **Train staff** on troubleshooting

## Questions?

Common questions answered in:
- `DEV_VS_PROD.md` - Development vs Production
- `PRODUCTION_DEPLOYMENT.md` - Detailed technical guide
- `FAMILY_DAY_IDEAS.md` - Game design and challenges

---

**Ready to Deploy?**

```bash
./deploy-to-openshift.sh
```

That's it! 🚀

