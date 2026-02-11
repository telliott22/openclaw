output "server_ip" {
  description = "Public IPv4 address of the OpenClaw server"
  value       = hcloud_server.openclaw.ipv4_address
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh root@${hcloud_server.openclaw.ipv4_address}"
}

output "tunnel_command" {
  description = "SSH tunnel command to access the UI"
  value       = "ssh -N -L 18789:127.0.0.1:18789 root@${hcloud_server.openclaw.ipv4_address}"
}

output "ui_url" {
  description = "UI URL (accessible after tunnel is running)"
  value       = "http://127.0.0.1:18789/"
}
