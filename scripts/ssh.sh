#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../infra"

IP=$(tofu output -raw server_ip 2>/dev/null)

if [ -z "$IP" ]; then
  echo "Error: No server IP found. Run ./scripts/deploy.sh first."
  exit 1
fi

echo "==> Connecting to OpenClaw at $IP"
echo "    UI tunnel: http://127.0.0.1:18789/"
echo "    Press Ctrl+C to disconnect"
echo ""

ssh -L 18789:127.0.0.1:18789 root@"$IP"
