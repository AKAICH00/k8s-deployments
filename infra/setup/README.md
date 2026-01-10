# Interactive setup CLI

A small helper to drive the Hetzner k3s Terraform module interactively or via a machine-provided answers file.

## Usage

```bash
cd infra/setup
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Interactive plan
python cli.py plan

# Non-interactive apply (answers file)
python cli.py apply --answers answers.yaml --auto-approve

# Fetch kubeconfig after apply
python cli.py kubeconfig <control_plane_ip>
```

## Answers file (YAML)

```yaml
cluster_name: demo
location: fsn1
control_plane_server_type: cx31
agent_server_type: cx31
agent_count: 2
enable_public_ssh: false
enable_public_k8s_api: false
tailscale_authkey: "env:TS_AUTHKEY"
allowed_ssh_cidrs: []
allowed_k8s_api_cidrs: []
ssh_public_key_path: ~/.ssh/id_ed25519.pub
```

Notes:
- `env:VAR_NAME` values are resolved from environment variables at runtime (keeps secrets out of the file).
- The CLI will list available starter apps from `apps/` and let you pick one; it also asks for a database preference (redis/postgres/mysql/none) for future automation hooks.
- Public ports are off by default; enable deliberately if needed.
