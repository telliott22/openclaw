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

# Generate these with: openssl rand -hex 32
openclaw_gateway_token = "generate-me"
gog_keyring_password   = "generate-me"
```

### 3. Deploy

```sh
./scripts/deploy.sh
```

This creates a Hetzner VM, installs Docker, clones OpenClaw, and starts the gateway.

### 4. Wait for cloud-init (first deploy only)

Takes 5-6 minutes. Monitor progress:

```sh
ssh root@<IP>
tail -f /var/log/cloud-init-output.log
# Wait for "OpenClaw deployment complete"
```

### 5. Post-deploy setup

SSH into the VM and run these commands:

```sh
ssh root@<IP>
cd /opt/openclaw

# Set gateway mode
docker compose exec openclaw-gateway node openclaw.mjs config set gateway.mode local

# Create required directories
docker compose exec openclaw-gateway mkdir -p /home/node/.openclaw/agents/main/sessions /home/node/.openclaw/credentials
docker compose exec openclaw-gateway chmod 700 /home/node/.openclaw

# Auto-fix remaining issues
docker compose exec openclaw-gateway node openclaw.mjs doctor --fix

# Restart to apply
docker compose restart
```

### 6. Install extra dependencies

Some skills need additional packages inside the container:

```sh
docker exec -u root $(docker ps -q --filter name=openclaw) bash -c \
  "apt-get update && apt-get install -y ffmpeg libnss3 libatk-bridge2.0-0 \
  libdrm2 libxcomposite1 libxdamage1 libxrandr2 libgbm1 libpango-1.0-0 \
  libcairo2 libasound2 libxshmfence1 python3-pip"
```

### 7. Connect the UI

Get your dashboard URL (includes auth token):

```sh
docker compose exec openclaw-gateway node openclaw.mjs dashboard --no-open
```

This prints a URL like `http://127.0.0.1:18789/#token=<your-token>`.

In a separate terminal, open the SSH tunnel:

```sh
./scripts/ssh.sh
```

Then open the dashboard URL in your browser. The UI will show "pairing required" — approve it:

```sh
docker compose exec openclaw-gateway node openclaw.mjs devices list
docker compose exec openclaw-gateway node openclaw.mjs devices approve <request-id>
```

### 8. Onboard

Run the interactive setup wizard in your SSH session:

```sh
docker compose exec -it openclaw-gateway node openclaw.mjs onboard
```

This walks you through setting up LLM API keys (Anthropic/OpenAI), messaging channels (WhatsApp, Telegram), web search, and more.

### 9. Pair Telegram

After onboarding, message your OpenClaw Telegram bot. It will give you a pairing code. Approve it:

```sh
docker compose exec openclaw-gateway node openclaw.mjs pairing approve telegram <CODE>
```

## Day-to-day usage

**Connect to UI:**
```sh
./scripts/ssh.sh
# Then open http://127.0.0.1:18789/
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

**List available skills:**
```sh
docker compose exec openclaw-gateway node openclaw.mjs skills list
```

**List connected channels:**
```sh
docker compose exec openclaw-gateway node openclaw.mjs channels list
```

## Tear down

```sh
./scripts/destroy.sh
```

Removes everything — server, firewall, SSH key, IP address. Nothing persists on Hetzner. You stop paying immediately.

## Security

- **No open ports** — the UI (port 18789) is only accessible via SSH tunnel, never exposed to the internet
- **SSH key-only auth** — password auth is disabled, SSH open to any IP for convenience
- **Secrets gitignored** — `terraform.tfvars` is in `.gitignore`
- **Auto-updates** — `unattended-upgrades` keeps the VM patched
- **Non-root container** — OpenClaw runs as UID 1000
- **Server protection** — `lifecycle { ignore_changes = [user_data] }` prevents accidental server destruction on `tofu apply`

## Cost

Hetzner CX23: **~$4/month** (2 vCPU, 4GB RAM, 40GB SSD, 20TB traffic). Destroy when not using to pay nothing.

## Troubleshooting

**UI shows "token missing":** Open the dashboard URL with the `#token=` hash (from step 7), not just `http://127.0.0.1:18789/`.

**UI shows "pairing required":** Run `devices list` and `devices approve` (step 7).

**Container keeps restarting:** Check `docker logs openclaw-gateway`. Common cause: wrong `command` in docker-compose — the correct one is `["node", "openclaw.mjs", "gateway", "--allow-unconfigured", "--bind", "lan"]`.

**Can't SSH after switching WiFi:** This shouldn't happen — SSH is open to all IPs. If it does, check Hetzner firewall in the console.

**Server got destroyed on `tofu apply`:** The `lifecycle` block should prevent this. If you removed it and `user_data` changed, tofu will recreate the server. All container config will be lost.
