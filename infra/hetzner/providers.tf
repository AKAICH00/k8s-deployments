variable "hcloud_token" {
  description = "Hetzner Cloud API token. If unset, the provider will use the HCLOUD_TOKEN environment variable."
  type        = string
  sensitive   = true
  default     = null
}

provider "hcloud" {
  token = var.hcloud_token
}
