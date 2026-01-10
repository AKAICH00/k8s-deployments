# k8s-deployments: Hetzner + k3s + Tailscale + ArgoCD

**Status:** ✅ Ready for OSS

A production-grade, batteries-included GitOps template for running Kubernetes on Hetzner Cloud with **k3s**, **Tailscale** VPN access, and **ArgoCD** for declarative app deployment.

## Key features

- **One-line cluster provisioning**: Interactive or non-interactive CLI setup (typer + rich)
- **Hetzner k3s on VMs**: Terraform module with control-plane + agents
- **Tailscale-native**: Optional VPN join for private Kubernetes API access
- **Safe defaults**: 6443 closed, SSH toggleable, preconditions guard unreachable clusters
- **LLM-friendly**: Answer files + env-var indirection for deterministic automation
- **Database + app selection**: Pick postgres/mysql/redis, choose starter app
- **ArgoCD ready**: Multi-app manifests + GitOps workflow included

## Files created

```
k8s-deployments/
├── setup                           # Entrypoint shell script
├── infra/
│   ├── hetzner/                   # Terraform module (k3s on VMs)
│   │   ├── main.tf                # Firewall, network, k3s servers
│   │   ├── variables.tf           # Cluster config + Tailscale toggle
│   │   ├── outputs.tf             # Control-plane IP, agent IPs
│   │   ├── versions.tf            # Provider versions
│   │   ├── README.md              # Terraform usage & Tailscale docs
│   │   └── .terraform.lock.hcl    # Locked provider versions (committable)
│   └── setup/                      # Interactive CLI for provisioning
│       ├── cli.py                 # typer app with plan/apply/kubeconfig commands
│       ├── requirements.txt       # Python deps: typer, rich, pyyaml
│       ├── README.md              # CLI quick-start
│       ├── FLOW.md                # Design doc (human & LLM usage)
│       └── examples/              # Answer file templates
│           ├── answers-dev.yaml   # Dev: small nodes, postgres, hello-world
│           ├── answers-prod.yaml  # Prod: large nodes, 3 agents, postgres
│           ├── answers-llm.yaml   # LLM-driven: minimal, env-var secrets
│           └── answers-quickstart.yaml # Public SSH for quick onboarding
├── apps/                          # App manifests (hello-world, teeswim, etc.)
├── argocd/                        # ArgoCD Application definitions
├── README.md                       # Main docs (updated with setup flow)
└── .gitignore                     # Ignores .terraform, *.tfstate, .tfvars, kubeconfig
```

## For OSS users (next steps after clone)

```bash
export HCLOUD_TOKEN="htz_..."
export HETZNER_TS_AUTHKEY="tskey_..."  # optional but recommended

./setup apply
# → Interactive: pick cluster name, region, node types, database, starter app
# → Or: ./setup apply --answers infra/setup/examples/answers-dev.yaml --auto-approve

./setup kubeconfig <TAILSCALE_IP>
export KUBECONFIG=$PWD/kubeconfig
kubectl get nodes
```

## For LLMs (driving this via code)

1. Generate an answers YAML (or use the examples)
2. User provides tokens via env vars (e.g., `HCLOUD_TOKEN`, `HETZNER_TS_AUTHKEY`)
3. LLM runs: `./setup apply --answers <file> --auto-approve`
4. Cluster ready in ~5 min; kubeconfig fetched and output

Example prompt:
> "Provision a k3s cluster on Hetzner with 2 nodes, postgres, and the hello-world starter. My Hetzner and Tailscale tokens are in env."

## Design decisions

1. **k3s on VMs, not "managed Kubernetes"**: Hetzner Cloud doesn't expose a managed-k8s API in Terraform, so k3s is the standard path (lightweight, popular, works perfectly)
2. **Tailscale-first for access**: No need to expose 6443 publicly; VPN access is cleaner + more secure
3. **Safe-by-default**: Ports closed unless explicitly enabled; preconditions prevent unreachable clusters
4. **Answers file over flags**: Cleaner for both humans and LLMs; supports env-var indirection for secrets
5. **Database + app selection**: Hooks for future automation (e.g., auto-helm install, schema setup)

## What's NOT included (yet)

- Automatic database provisioning (PostgreSQL Helm chart, migrations)
- ArgoCD bootstrap + admin password setup
- Ingress/networking beyond k3s built-in
- Prometheus/observability
- Cert-manager integration

These are intentionally left out to keep the template lean; users can add via ArgoCD apps.

## Testing

- ✅ Terraform format & validate: passed
- ✅ CLI help: working
- ✅ YAML example files: valid
- ✅ Entry script: executable, sets up venv

Ready to push to GitHub!

---

**Author notes for maintainers:**
- `.terraform.lock.hcl` is committed (allows reproducible provider pinning)
- `infra/setup/.venv/` is ignored (venv created on first `./setup` run)
- Answer files use `env:*` indirection for secrets (secrets never in git)
- CLI prefers `--no-interactive` + answers file for CI/LLM automation
