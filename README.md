# OpenClaw on Hetzner Cloud

Personal AI agent that handles your inbox, calendar, and emails through WhatsApp/Telegram/Discord. Runs on a cheap Hetzner VM (~$4/month) with SSH-tunnel-only access.

## Prerequisites

- [OpenTofu](https://opentofu.org/docs/intro/install/) (`brew install opentofu`)
- A [Hetzner Cloud](https://console.hetzner.cloud/) account
- An SSH key at `~/.ssh/id_ed25519` (or change the path in tfvars)

## Setup

### 1. Get a Hetzner API token

1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Create a project (or use an existing one)
3. Go to **Security** → **API Tokens** → **Generate API Token**
4. Give it **Read & Write** access, copy the token

### 2. Configure

```sh
cp infra/terraform.tfvars.example infra/terraform.tfvars
```

Edit `infra/terraform.tfvars`:

```hcl
# Paste your Hetzner API token
hcloud_token = "your-token-here"

# Your public IP for SSH access (only this IP can connect)
# Find it: curl -s https://ifconfig.me
admin_ip_cidrs = ["1.2.3.4/32"]

# Generate these:
#   openssl rand -hex 32
openclaw_gateway_token = "generate-me"
gog_keyring_password   = "generate-me"
```

### 3. Deploy

```sh
./scripts/deploy.sh
```

This creates a Hetzner VM, installs Docker, clones OpenClaw, and starts the gateway. Takes about 3-5 minutes after `apply` completes for cloud-init to finish.

### 4. Connect

```sh
./scripts/ssh.sh
```

This opens an SSH session with a tunnel — the OpenClaw UI becomes available at:

**http://127.0.0.1:18789/**

### 5. Onboard

On the VM (via the SSH session from step 4), run:

```sh
cd /opt/openclaw
docker compose run --rm openclaw-cli onboard
```

This walks you through setting up your LLM API keys (Anthropic/OpenAI) and messaging integrations (WhatsApp, Telegram, etc).

## Day-to-day usage

**Connect to UI:**
```sh
./scripts/ssh.sh
# Then open http://127.0.0.1:18789/
```

**Check if cloud-init finished (first deploy only):**
```sh
ssh root@<IP>
tail -f /var/log/cloud-init-output.log
# Wait for "OpenClaw deployment complete"
```

**Check container status:**
```sh
ssh root@<IP>
docker ps
```

**View gateway logs:**
```sh
ssh root@<IP>
cd /opt/openclaw && docker compose logs -f
```

## Tear down

```sh
./scripts/destroy.sh
```

Removes everything — server, firewall, SSH key, IP address. Nothing persists on Hetzner. You stop paying immediately.

## Security

- **No open ports** — the UI (port 18789) is only accessible via SSH tunnel, never exposed to the internet
- **IP-restricted SSH** — firewall allows SSH only from your IP
- **Secrets gitignored** — `terraform.tfvars` is in `.gitignore`
- **Auto-updates** — `unattended-upgrades` keeps the VM patched
- **Non-root container** — OpenClaw runs as UID 1000

## Cost

Hetzner CX22: **~$4/month** (2 vCPU, 4GB RAM, 40GB SSD, 20TB traffic). Destroy when not using to pay nothing.
