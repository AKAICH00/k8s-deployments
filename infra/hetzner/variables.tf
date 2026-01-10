variable "cluster_name" {
  description = "Name prefix for the k3s cluster resources."
  type        = string
  default     = "k3s"
}

variable "location" {
  description = "Hetzner location, e.g. fsn1, nbg1, hel1."
  type        = string
  default     = "fsn1"
}

variable "network_zone" {
  description = "Hetzner network zone for the private network (e.g. eu-central, eu-west, us-east)."
  type        = string
  default     = "eu-central"
}

variable "control_plane_server_type" {
  description = "Hetzner server type for the k3s server node."
  type        = string
  default     = "cx31"
}

variable "agent_server_type" {
  description = "Hetzner server type for k3s agent nodes."
  type        = string
  default     = "cx31"
}

variable "agent_count" {
  description = "Number of agent nodes."
  type        = number
  default     = 2
}

variable "image" {
  description = "OS image name. Ubuntu is a safe default for k3s."
  type        = string
  default     = "ubuntu-24.04"
}

variable "ssh_public_key_path" {
  description = "Path to an SSH public key to register in Hetzner and allow root SSH access."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "tailscale_authkey" {
  description = "Optional Tailscale auth key (prefer an ephemeral, pre-approved key). If set, the control-plane joins your tailnet and you can access the Kubernetes API over Tailscale."
  type        = string
  sensitive   = true
  default     = null
}

variable "tailscale_tags" {
  description = "Optional list of tags to apply when bringing up Tailscale (e.g. [\"tag:k8s\"]). Requires the auth key to be allowed to use those tags."
  type        = list(string)
  default     = []
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH to the nodes."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "enable_public_ssh" {
  description = "Whether to allow inbound SSH (port 22) from allowed_ssh_cidrs. If false, prefer Tailscale SSH or console access."
  type        = bool
  default     = true
}

variable "allowed_k8s_api_cidrs" {
  description = "CIDR blocks allowed to access the Kubernetes API (6443). Only used when enable_public_k8s_api is true."
  type        = list(string)
  default     = []
}

variable "enable_public_k8s_api" {
  description = "Whether to expose the Kubernetes API (port 6443) publicly. Recommended false when using Tailscale."
  type        = bool
  default     = false
}

variable "require_access_method" {
  description = "Safety switch: require either public SSH or Tailscale auth key so you don't provision an unreachable cluster."
  type        = bool
  default     = true
}

locals {
  access_ok = (!var.require_access_method) || var.enable_public_ssh || (var.tailscale_authkey != null && trim(var.tailscale_authkey) != "")
}
