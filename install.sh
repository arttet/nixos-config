#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting NixOS Configuration migration..."

REPO_URL="https://github.com/arttet/nixos-config.git"
REPO_BRANCH="main"
REPO_DIR="${NIX_CONFIG_INSTALL_REPO_DIR:-/root/.cache/nixos-config-installer/repo}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

if [ "$(id -u)" -ne 0 ]; then
  echo "error: installer must be run as root from the NixOS live environment" >&2
  exit 1
fi

require_command git
require_command nix

mkdir -p "$(dirname "$REPO_DIR")"

if [ ! -d "$REPO_DIR" ]; then
  echo "==> Cloning repository..."
  git clone --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
else
  if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: $REPO_DIR exists but is not a git repository" >&2
    exit 1
  fi

  echo "==> Updating repository..."
  git -C "$REPO_DIR" checkout "$REPO_BRANCH"
  git -C "$REPO_DIR" pull --ff-only origin "$REPO_BRANCH"
fi

cd "$REPO_DIR"

echo "==> Starting interactive installer..."
nix --extra-experimental-features "nix-command flakes" shell nixpkgs#nushell nixpkgs#mkpasswd nixpkgs#openssl -c nu scripts/install/bootstrap.nu --apply
