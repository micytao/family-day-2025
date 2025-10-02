# RHAIIS Deployment Configuration

## Important: Hugging Face Token

Before deploying, you need to replace the placeholder token in `rhaiis-deployment.yml`:

1. Get your Hugging Face token from: https://huggingface.co/settings/tokens
2. Open `rhaiis-deployment.yml`
3. Find the line: `HF_TOKEN: "YOUR_HUGGING_FACE_TOKEN_HERE"`
4. Replace with your actual token: `HF_TOKEN: "hf_your_actual_token"`

## Quick Deploy

```bash
# Replace token in the file first!
# Then deploy:
kubectl apply -f rhaiis-deployment.yml

# Check deployment
kubectl get pods -n rhaiis
kubectl logs -f deployment/rhaiis -n rhaiis
```

## What This Deploys

- **Model:** Qwen/Qwen2-VL-2B-Instruct (2B parameters)
- **Service:** rhaiis-service on port 8000
- **Route:** rhaiis-route for external access
- **Storage:** 50Gi PVC for model cache
- **GPU:** Requires 1 NVIDIA GPU

## Security Note

⚠️ **Never commit your actual Hugging Face token to Git!**

The `rhaiis-deployment.yml` file in this repository has the token masked as `YOUR_HUGGING_FACE_TOKEN_HERE`.

Keep your actual token secure and only add it when deploying.

