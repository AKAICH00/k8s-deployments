# Setup CLI: Complete Flow

## For humans (interactive)

```bash
export HCLOUD_TOKEN="your_hetzner_token"
export HETZNER_TS_AUTHKEY="your_tailscale_authkey"

./setup apply
# → Prompts for cluster name, region, node types, db choice, starter app
# → Runs terraform apply
# → Outputs kubeconfig fetch command
```

## For LLM/automation (non-interactive)

```bash
export HCLOUD_TOKEN="your_hetzner_token"
export HETZNER_TS_AUTHKEY="your_tailscale_authkey"

./setup apply --answers infra/setup/examples/answers-llm.yaml --auto-approve
# → Reads all config from answers file
# → Resolves env:* vars from environment
# → Runs terraform without interactive prompts
# → Exits with status 0 on success
```

## Key Design Points

1. **Secrets in environment, not files**
   - `tailscale_authkey: "env:HETZNER_TS_AUTHKEY"` in the answers file
   - At runtime, the CLI resolves `env:*` refs to actual env vars
   - Keeps tokens out of git and out of temp files (cleaned up after apply)

2. **Database + starter app selection**
   - CLI lists available starters from `apps/` folder
   - User picks database type (postgres/mysql/redis/none)
   - Future hook: can auto-bootstrap helm charts, ArgoCD apps based on these choices

3. **Safe-by-default**
   - Kubernetes API (6443) closed unless explicitly enabled with a CIDR
   - SSH (22) off unless enabled
   - Requires either public SSH or Tailscale auth key so you don't create an unreachable cluster

4. **Example files for all use cases**
   - `answers-llm.yaml`: minimal, env-var-driven, zero prompts
   - `answers-dev.yaml`: full setup with postgres + hello-world starter
   - `answers-prod.yaml`: larger nodes (cx41), 3 agents, postgres
   - `answers-quickstart.yaml`: public SSH for quick onboarding (lock it down after!)

## What happens inside `./setup apply`

1. Gathers answers from prompts or file
2. Lists available starters from `apps/` (e.g., hello-world, teeswim-api, etc.)
3. Resolves `env:*` variables
4. Validates access config (must have SSH or Tailscale)
5. Writes a temp `terraform.tfvars.json`
6. Runs `terraform init/plan/apply` from `infra/hetzner/`
7. Fetches terraform outputs (control-plane IP)
8. Prints next steps: `./setup kubeconfig <IP>`

## LLM Integration

The answers file + env-var approach means an LLM assistant (like me) can:
1. Generate an answers YAML with cluster config
2. User provides `HCLOUD_TOKEN` and optional `HETZNER_TS_AUTHKEY`
3. User runs: `./setup apply --answers <file> --auto-approve`
4. Cluster provisioned and kubeconfig fetched automatically

Example prompt to an LLM:
> "I want to provision a k3s cluster on Hetzner with 3 nodes, postgres, and deploy the hello-world starter. My tokens are in env. Generate an answers.yaml and the command to run."
