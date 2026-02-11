variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key to upload"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cx22"
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "fsn1"
}

variable "admin_ip_cidrs" {
  description = "CIDR blocks allowed to SSH (your IP)"
  type        = list(string)
}

variable "openclaw_gateway_token" {
  description = "Authentication token for OpenClaw gateway"
  type        = string
  sensitive   = true
}

variable "gog_keyring_password" {
  description = "Keyring encryption password for OpenClaw"
  type        = string
  sensitive   = true
}
