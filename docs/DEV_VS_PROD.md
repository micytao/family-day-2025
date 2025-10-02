# Development vs Production Comparison

## Quick Reference

| Feature | index.html (Development) | prod-index.html (Production) |
|---------|-------------------------|------------------------------|
| **Default Endpoint** | `http://localhost:8080` | Empty (Proxy mode) |
| **Primary Target** | llama.cpp / Ollama | vLLM on OpenShift |
| **Port** | 8080 (llama.cpp) / 11434 (Ollama) | 8000 (vLLM) |
| **Preset Buttons** | Ollama, llama.cpp, Clear | vLLM, Ollama, llama.cpp, OpenShift Proxy |
| **Test Function** | Basic connection test | Basic + Advanced vLLM test |
| **Deployment** | Local file or simple server | OpenShift with cross-namespace proxy |
| **CORS Handling** | Direct connection | Proxied through nginx/service mesh |

## Key Differences

### 1. Default API Endpoint Detection

**Development (index.html):**
```javascript
// Defaults to llama.cpp
if (protocol === 'file:') {
    return "http://localhost:8080";
}
```

**Production (prod-index.html):**
```javascript
// Defaults to proxy mode for OpenShift
if (protocol === 'file:') {
    return "http://localhost:8000";  // vLLM for local testing
}
// Production deployment returns "" (proxy mode)
```

### 2. Preset Endpoints

**Development:**
- Ollama:11434
- llama.cpp:8080
- Clear

**Production:**
- **vLLM:8000** ← New!
- Ollama:11434
- llama.cpp:8080
- **OpenShift Proxy** ← New! (uses relative paths)

### 3. Test Functions

**Development:**
- `testConnection()` - Basic API test

**Production:**
- `testConnection()` - Basic API test
- **`testVLLMConnection()`** ← New! - Comprehensive vLLM test
  - Tests `/v1/models` endpoint
  - Tests `/v1/chat/completions` endpoint
  - Provides detailed troubleshooting info

### 4. Error Messages

**Production includes additional guidance for:**
- vLLM-specific issues
- OpenShift deployment troubleshooting
- Cross-namespace networking
- Service route configuration

### 5. UI Elements

**Production:**
- Additional "Test vLLM (Advanced)" button
- Updated help text mentioning OpenShift
- Title includes "[PRODUCTION]" tag
- HTML comments with deployment instructions

## When to Use Which Version

### Use `index.html` (Development) when:
- 🔧 Local development and testing
- 💻 Running llama.cpp or Ollama locally
- 🎮 Quick demos on a laptop
- 📚 Learning and experimentation

### Use `prod-index.html` (Production) when:
- 🏢 Deploying to OpenShift cluster
- 🚀 Using Red Hat AI Inference Server (vLLM)
- 🔒 Need cross-namespace service communication
- 📊 Production environment with proper infrastructure
- 👥 Serving multiple users at Family Day event

## Migration Path: Dev → Prod

1. **Test locally with vLLM:**
   ```bash
   # Start vLLM locally
   vllm serve model-name --port 8000
   
   # Open prod-index.html
   # Click "vLLM:8000" preset
   # Test with "Test vLLM (Advanced)"
   ```

2. **Deploy to OpenShift:**
   ```bash
   # Follow PRODUCTION_DEPLOYMENT.md
   ./deploy-to-openshift.sh
   ```

3. **Verify:**
   - Access via route URL
   - Click "OpenShift Proxy"
   - Run "Test vLLM (Advanced)"
   - All checks should pass ✅

## Configuration Examples

### Development Setup

```bash
# Terminal 1: Start llama.cpp
./llama-server --model model.gguf --port 8080 --cors

# Terminal 2: Serve HTML
python -m http.server 3000

# Browser: http://localhost:3000/index.html
```

### Production Setup

```bash
# Deploy to OpenShift
oc new-project family-day
oc create configmap family-day-html --from-file=prod-index.html
kubectl apply -f openshift-deployment.yaml

# Access via route
ROUTE=$(oc get route family-day-service -o jsonpath='{.spec.host}')
echo "https://$ROUTE"
```

## Testing Checklist

### Development (index.html)
- [ ] llama.cpp connection works
- [ ] Ollama connection works
- [ ] Camera access granted
- [ ] Image capture functional
- [ ] Vision model responds correctly

### Production (prod-index.html)
- [ ] vLLM endpoint reachable
- [ ] `/v1/models` returns model list
- [ ] `/v1/chat/completions` works
- [ ] OpenShift proxy mode functional
- [ ] Camera access works over HTTPS
- [ ] Cross-namespace communication verified
- [ ] Image capture and processing work
- [ ] Vision model responds correctly

## API Compatibility

Both versions use the **OpenAI-compatible Chat Completions API**:

```javascript
{
  "model": "model-name",
  "max_tokens": 100,
  "messages": [
    { 
      "role": "user", 
      "content": [
        { "type": "text", "text": "What's in this image?" },
        { 
          "type": "image_url", 
          "image_url": { "url": "data:image/jpeg;base64,..." }
        }
      ]
    }
  ]
}
```

✅ Works with: llama.cpp, Ollama, vLLM, OpenAI API
✅ Supports: Vision-Language Models
✅ Format: OpenAI Chat Completions v1

## Troubleshooting

### Issue: "Can't connect to vLLM"
- **Dev:** Not expected to have vLLM running
- **Prod:** Check vLLM pod status, service configuration, and network policies

### Issue: "CORS errors"
- **Dev:** Ensure server started with `--cors` flag
- **Prod:** Check nginx proxy configuration and CORS headers

### Issue: "Camera not working"
- **Dev:** Works over HTTP (localhost)
- **Prod:** Requires HTTPS (OpenShift route with TLS)

## Summary

| Aspect | Development | Production |
|--------|-------------|------------|
| **Complexity** | Simple, single file | Multi-component deployment |
| **Infrastructure** | Local machine | OpenShift cluster |
| **Scalability** | 1 user | Multiple concurrent users |
| **Reliability** | Best-effort | High availability |
| **Security** | Minimal | TLS, network policies, RBAC |
| **Monitoring** | Console logs | Full observability stack |

---

**Quick Start:**
- Development: Just open `index.html` in a browser
- Production: Follow `PRODUCTION_DEPLOYMENT.md` guide

