terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

# Upload SSH public key
resource "hcloud_ssh_key" "openclaw" {
  name       = "openclaw"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# Firewall: SSH open (key-auth only), all outbound allowed
resource "hcloud_firewall" "openclaw" {
  name = "openclaw"

  # SSH inbound (key-auth only, no password)
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # All outbound (LLM API calls, Docker pulls, apt)
  rule {
    direction       = "out"
    protocol        = "tcp"
    port            = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction       = "out"
    protocol        = "udp"
    port            = "any"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }

  rule {
    direction       = "out"
    protocol        = "icmp"
    destination_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Server
resource "hcloud_server" "openclaw" {
  name        = "openclaw"
  server_type = var.server_type
  location    = var.location
  image       = "ubuntu-24.04"

  ssh_keys = [hcloud_ssh_key.openclaw.id]

  firewall_ids = [hcloud_firewall.openclaw.id]

  user_data = templatefile("${path.module}/cloud-init.yml", {
    openclaw_gateway_token = var.openclaw_gateway_token
    gog_keyring_password   = var.gog_keyring_password
  })

  # CRITICAL: Never recreate the server for cloud-init changes.
  # cloud-init only runs on first boot anyway.
  lifecycle {
    ignore_changes = [user_data]
  }
}
