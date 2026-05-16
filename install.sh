#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting NixOS Platform migration..."

REPO_DIR="/tmp/nixos-config"
REPO_URL="https://github.com/arttet/nixos-config.git"

if [ ! -d "$REPO_DIR" ]; then
  echo "==> Cloning repository..."
  git clone "$REPO_URL" "$REPO_DIR"
else
  echo "==> Updating repository..."
  cd "$REPO_DIR"
  git pull origin main
fi

cd "$REPO_DIR"

echo "==> Starting interactive installer..."
nix --extra-experimental-features "nix-command flakes" shell nixpkgs#nushell -c nu scripts/install/bootstrap.nu --apply
