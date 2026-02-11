#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../infra"

if [ ! -f terraform.tfvars ]; then
  echo "Error: infra/terraform.tfvars not found."
  echo "Copy terraform.tfvars.example and fill in your values."
  exit 1
fi

echo "==> Initializing OpenTofu..."
tofu init

echo ""
echo "==> Planning..."
tofu plan

echo ""
read -p "Apply these changes? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  tofu apply -auto-approve
  echo ""
  echo "==> Deployed! Wait 3-5 min for cloud-init, then run: ./scripts/ssh.sh"
else
  echo "Aborted."
fi
