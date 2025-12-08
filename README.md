# k8s-deployments

GitOps repository for Kubernetes deployments managed by ArgoCD.

## Structure

```
k8s-deployments/
├── apps/                    # Application manifests
│   └── hello-world/         # Hello World test app
│       ├── deployment.yaml
│       ├── service.yaml
│       └── kustomization.yaml
├── argocd/                  # ArgoCD Application definitions
│   └── hello-world-app.yaml
└── README.md
```

## How It Works

1. **Push code** to your app repository
2. **Build & push** Docker image to GHCR
3. **Update image tag** in this repo (e.g., `apps/hello-world/deployment.yaml`)
4. **ArgoCD auto-syncs** the change to Kubernetes

## ArgoCD Access

- **URL:** https://100.97.89.1:30443 (Tailscale only)
- **Username:** admin
- **Password:** See KUBEDB docs

## Adding a New App

1. Create folder: `apps/your-app/`
2. Add `deployment.yaml`, `service.yaml`, `kustomization.yaml`
3. Create ArgoCD Application in `argocd/your-app.yaml`
4. Apply: `kubectl apply -f argocd/your-app.yaml`

## Image Update Example

To promote a new version:
```bash
# Update image tag in deployment.yaml
sed -i 's|image: ghcr.io/akaich00/hello-world:.*|image: ghcr.io/akaich00/hello-world:v1.2.3|' apps/hello-world/deployment.yaml
git add . && git commit -m "Promote hello-world to v1.2.3" && git push
```

ArgoCD will automatically detect the change and deploy.
