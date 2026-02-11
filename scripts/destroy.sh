#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../infra"

echo "!! This will destroy ALL OpenClaw infrastructure on Hetzner !!"
echo "   (server, firewall, SSH key, IP address)"
echo ""
read -p "Type 'destroy' to confirm: " confirm

if [ "$confirm" = "destroy" ]; then
  tofu destroy -auto-approve
  echo ""
  echo "==> All resources destroyed."
else
  echo "Aborted."
fi
