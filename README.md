# k8s-deployments

GitOps repository for Kubernetes deployments managed by ArgoCD.

## Quick start (provision a Hetzner k3s cluster)

```bash
# 1. Set your Hetzner API token
export HCLOUD_TOKEN="htz_..."

# 2. (Optional but recommended) Set a Tailscale auth key
export HETZNER_TS_AUTHKEY="tskey_..."

# 3. Run the setup CLI (interactive or non-interactive)
./setup apply              # interactive: prompts for all values

# OR non-interactive (e.g., for LLM/CI automation)
./setup apply --answers infra/setup/examples/answers-dev.yaml --auto-approve

# 4. Fetch kubeconfig
./setup kubeconfig <control_plane_ip_or_tailscale_ip>

# 5. Verify and deploy apps via ArgoCD
export KUBECONFIG=$PWD/kubeconfig
kubectl get nodes
kubectl apply -f argocd/hello-world-app.yaml
```

See [infra/setup/README.md](infra/setup/README.md) for full CLI docs, and [infra/hetzner/README.md](infra/hetzner/README.md) for Terraform module details.

## Structure

```
k8s-deployments/
├── infra/
│   ├── setup/                  # Interactive CLI for provisioning
│   │   ├── cli.py
│   │   ├── requirements.txt
│   │   └── examples/           # Example answers files (dev, prod, llm, quickstart)
│   └── hetzner/                # Terraform module for k3s on Hetzner
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── README.md
├── apps/                    # Application manifests
│   └── hello-world/         # Hello World test app
│       ├── deployment.yaml
│       ├── service.yaml
│       └── kustomization.yaml
├── argocd/                  # ArgoCD Application definitions
│   └── hello-world-app.yaml
├── setup                    # Entry script for CLI (calls infra/setup/cli.py)
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
