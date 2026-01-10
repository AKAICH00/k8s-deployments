output "control_plane_public_ip" {
  value       = hcloud_server.control_plane.ipv4_address
  description = "Public IPv4 address of the k3s control-plane node."
}

output "agent_public_ips" {
  value       = [for s in hcloud_server.agents : s.ipv4_address]
  description = "Public IPv4 addresses of the k3s agent nodes."
}

output "get_kubeconfig_command" {
  value = "ssh root@${hcloud_server.control_plane.ipv4_address} 'sudo cat /etc/rancher/k3s/k3s.yaml'"
}
