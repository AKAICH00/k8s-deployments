locals {
  network_cidr = "10.10.0.0/16"
  subnet_cidr  = "10.10.1.0/24"
}

resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

resource "hcloud_network" "this" {
  name     = "${var.cluster_name}-net"
  ip_range = local.network_cidr
}

resource "hcloud_network_subnet" "this" {
  network_id   = hcloud_network.this.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = local.subnet_cidr
}

resource "hcloud_ssh_key" "this" {
  name       = "${var.cluster_name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "hcloud_firewall" "this" {
  name = "${var.cluster_name}-fw"

  dynamic "rule" {
    for_each = var.enable_public_ssh ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "22"
      source_ips = var.allowed_ssh_cidrs
    }
  }

  dynamic "rule" {
    for_each = var.enable_public_k8s_api ? [1] : []
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = "6443"
      source_ips = var.allowed_k8s_api_cidrs
    }
  }

  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

resource "terraform_data" "access_guard" {
  input = {
    access_ok = local.access_ok
  }

  lifecycle {
    precondition {
      condition     = local.access_ok
      error_message = "No access method configured. Set enable_public_ssh=true and allowed_ssh_cidrs, or provide tailscale_authkey (recommended)."
    }

    precondition {
      condition     = !var.enable_public_k8s_api || length(var.allowed_k8s_api_cidrs) > 0
      error_message = "enable_public_k8s_api=true requires allowed_k8s_api_cidrs to be non-empty."
    }

    precondition {
      condition     = !var.enable_public_ssh || length(var.allowed_ssh_cidrs) > 0
      error_message = "enable_public_ssh=true requires allowed_ssh_cidrs to be non-empty."
    }
  }
}

resource "hcloud_server" "control_plane" {
  name        = "${var.cluster_name}-cp1"
  server_type = var.control_plane_server_type
  image       = var.image
  location    = var.location

  ssh_keys = [hcloud_ssh_key.this.id]

  firewall_ids = [hcloud_firewall.this.id]

  network {
    network_id = hcloud_network.this.id
  }

  user_data = <<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: true

    runcmd:
      - |
        set -euo pipefail

        TS_IP=""
        if [ -n "${var.tailscale_authkey}" ]; then
          curl -fsSL https://tailscale.com/install.sh | sh

          TS_ARGS=("--authkey=${var.tailscale_authkey}" "--ssh")
          if [ ${length(var.tailscale_tags)} -gt 0 ]; then
            TS_ARGS+=("--advertise-tags=${join(",", var.tailscale_tags)}")
          fi

          tailscale up "$${TS_ARGS[@]}"
          TS_IP="$(tailscale ip -4 | head -n1 || true)"
        fi

        PUBLIC_IP="$(curl -fsS https://api.ipify.org || true)"

        TLS_SAN_ARGS=()
        if [ -n "$PUBLIC_IP" ]; then
          TLS_SAN_ARGS+=("--tls-san" "$PUBLIC_IP")
        fi
        if [ -n "$TS_IP" ]; then
          TLS_SAN_ARGS+=("--tls-san" "$TS_IP")
        fi

          curl -sfL https://get.k3s.io | K3S_TOKEN=${random_password.k3s_token.result} sh -s - server "$${TLS_SAN_ARGS[@]}"
  CLOUDINIT

  depends_on = [hcloud_network_subnet.this]
}

resource "hcloud_server" "agents" {
  count       = var.agent_count
  name        = "${var.cluster_name}-agent${count.index + 1}"
  server_type = var.agent_server_type
  image       = var.image
  location    = var.location

  ssh_keys = [hcloud_ssh_key.this.id]

  firewall_ids = [hcloud_firewall.this.id]

  network {
    network_id = hcloud_network.this.id
  }

  user_data = <<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: true

    runcmd:
      - curl -sfL https://get.k3s.io | K3S_URL=https://${hcloud_server.control_plane.ipv4_address}:6443 K3S_TOKEN=${random_password.k3s_token.result} sh -
  CLOUDINIT

  depends_on = [hcloud_network_subnet.this, hcloud_server.control_plane]
}
