#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/arttet/nixos-config.git"
REPO_BRANCH="${BRANCH:-${NIX_CONFIG_INSTALL_REPO_BRANCH:-main}}"
REPO_DIR="${REPO_DIR:-${NIX_CONFIG_INSTALL_REPO_DIR:-/root/.cache/nixos-config-installer/repo}}"

CYAN='\033[1;36m'
GREEN='\033[1;32m'
NC='\033[0m'

echo -e "${CYAN}NixOS installer${NC}"
echo "Repository: $REPO_URL"
echo "Branch:     $REPO_BRANCH"
echo "Repo dir:   $REPO_DIR"
echo

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
  echo -e "${GREEN}[1/3] Cloning repository...${NC}"
  git clone --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"
else
  if ! git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: $REPO_DIR exists but is not a git repository" >&2
    exit 1
  fi

  echo -e "${GREEN}[1/3] Updating repository...${NC}"
  git -C "$REPO_DIR" fetch --prune origin "$REPO_BRANCH"
  git -C "$REPO_DIR" checkout -B "$REPO_BRANCH" FETCH_HEAD
  git -C "$REPO_DIR" reset --hard FETCH_HEAD
fi

cd "$REPO_DIR"

echo -e "${GREEN}[2/3] Preparing installer shell...${NC}"
echo -e "${GREEN}[3/3] Starting interactive installer...${NC}"
nix --extra-experimental-features "nix-command flakes" shell nixpkgs#nushell nixpkgs#mkpasswd nixpkgs#gum nixpkgs#coreutils nixpkgs#iputils nixpkgs#util-linux -c nu scripts/install/bootstrap.nu --apply
