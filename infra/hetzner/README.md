# Hetzner k3s cluster (Terraform)

Hetzner Cloud does not expose a first-party “managed Kubernetes” resource via the `hcloud` Terraform provider or the installed `hcloud` CLI, so this folder provisions a production-style Kubernetes cluster by running **k3s on Hetzner VMs**.

This is still GitOps-friendly: once the cluster is up, you point ArgoCD at this repo.

## Prereqs

- Terraform
- A Hetzner Cloud API token
- An SSH keypair on your machine (public key path is configurable)

## Auth (recommended)

Do not paste tokens into git.

```bash
export HCLOUD_TOKEN="..."
```

Terraform also supports passing `-var="hcloud_token=..."`.

## Create the cluster

From this folder:

```bash
terraform init
terraform apply
```

Defaults create:
- 1 control-plane node (`cx31`)
- 2 agent nodes (`cx31`)
- Ubuntu 24.04

Defaults are **safe-by-default**:
- Kubernetes API (6443) is **not** exposed publicly
- Use Tailscale access (recommended) or explicitly enable public access

Override via `-var` flags or a local `terraform.tfvars` (not committed).

## Access from anywhere via Tailscale

If your org uses Tailscale, you can avoid exposing the Kubernetes API (6443) publicly and access the cluster from **any device/user that’s in the same tailnet**.

1) Create a Tailscale **auth key** in the admin console (prefer **ephemeral**, optionally **pre-approved**, and (optionally) tag-scoped).

2) Apply with a Tailscale key so the **control-plane node** joins your tailnet:

```bash
terraform apply \
	-var='tailscale_authkey=tskey-...' \
	-var='tailscale_tags=["tag:k8s"]'
```

3) In the Tailscale admin console:
- Ensure the device appears and is approved (if not pre-approved)
- Ensure ACLs allow users/groups to reach it

4) Fetch kubeconfig over Tailscale SSH (or normal SSH):

```bash
ssh root@<TAILSCALE_IP> 'sudo cat /etc/rancher/k3s/k3s.yaml' > kubeconfig
sed -i '' 's/127.0.0.1/<TAILSCALE_IP>/g' kubeconfig
export KUBECONFIG=$PWD/kubeconfig
kubectl get nodes
```

Note: “any account” only works if those users are members of your tailnet (or you’ve explicitly shared access via Tailscale’s sharing/device-sharing features + ACLs).

## Optional: expose 6443 publicly (not recommended)

If you really need public API access, enable it explicitly and scope it:

```bash
terraform apply \
	-var='enable_public_k8s_api=true' \
	-var='allowed_k8s_api_cidrs=["<YOUR_IP>/32"]'
```

## Optional: disable public SSH when using Tailscale

If you want to rely on Tailscale SSH only:

```bash
terraform apply \
	-var='enable_public_ssh=false' \
	-var='tailscale_authkey=tskey-...'
```

## Fetch kubeconfig

After apply, Terraform outputs a helper SSH command. For a usable local kubeconfig, you typically want to replace `127.0.0.1` with the control-plane public IP:

```bash
ssh root@<CONTROL_PLANE_IP> 'sudo cat /etc/rancher/k3s/k3s.yaml' > kubeconfig
sed -i '' 's/127.0.0.1/<CONTROL_PLANE_IP>/g' kubeconfig
export KUBECONFIG=$PWD/kubeconfig
kubectl get nodes
```

## Security note

The defaults allow SSH (22) and the Kubernetes API (6443) from anywhere for quick bring-up. Tighten `allowed_ssh_cidrs` and `allowed_k8s_api_cidrs` before using this for production.
