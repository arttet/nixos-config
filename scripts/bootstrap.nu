# scripts/bootstrap.nu

# Main NixOS installation script
def main [
  target = "guest"
  user   = "example"
  disk   = ""        # auto-detect if empty
] {
  # Auto-detect primary disk
  let disk = if ($disk == "") {
    lsblk -dpno NAME,TYPE
    | lines
    | where { |l| $l | str contains "disk" }
    | first
    | split row " "
    | first
  } else { $disk }

  print $"Using disk: ($disk)"

  # Validate overlay before install — fail fast
  let check = (nix-instantiate --eval ~/.nixos-local/user.nix | complete)
  if $check.exit_code != 0 {
    error make { msg: "overlay ~/.nixos-local/user.nix is invalid — aborting" }
  }

  # Partition and format via disko
  nix run github:nix-community/disko -- \
    --mode disko \
    --arg diskDevice $'"($disk)"' \
    github:yourrepo#($target)

  # Install
  nixos-install --flake $"github:yourrepo#($target)" --no-root-passwd

  # Post-install smoke test
  print "--- Verification ---"
  nixos-option users.users.void
  nixos-option users.users.($user).extraGroups
}

# VPN Server Setup script
def setup-vpn-server [user = "example"] {
  # Generate Reality keypair
  let keys = (xray x25519 | complete)
  let private_key = ($keys.stdout | lines | where { |l| $l | str contains "Private" } | first | split row ": " | last)
  let public_key  = ($keys.stdout | lines | where { |l| $l | str contains "Public"  } | first | split row ": " | last)

  # Generate client UUID
  let uuid = (xray uuid)
  let short_id = (openssl rand -hex 8)

  # Write server config — never in git
  mkdir -p /etc/xray
  $"
{
  \"inbounds\": [{
    \"port\": 443,
    \"protocol\": \"vless\",
    \"settings\": {
      \"clients\": [{\"id\": \"($uuid)\", \"flow\": \"xtls-rprx-vision\"}],
      \"decryption\": \"none\",
      \"fallbacks\": [{\"dest\": \"127.0.0.1:8080\"}]
    },
    \"streamSettings\": {
      \"network\": \"tcp\",
      \"security\": \"reality\",
      \"realitySettings\": {
        \"dest\": \"www.microsoft.com:443\",
        \"serverNames\": [\"www.microsoft.com\"],
        \"privateKey\": \"($private_key)\",
        \"shortIds\": [\"($short_id)\"]
      }
    }
  }],
  \"outbounds\": [{\"protocol\": \"freedom\"}]
}
" | save /etc/xray/config.json

  # Print client config for overlay
  print "=== CLIENT CONFIG (add to overlay, never commit) ==="
  print $"UUID:       ($uuid)"
  print $"PublicKey:  ($public_key)"
  print $"ShortId:    ($short_id)"
  print $"ServerName: www.microsoft.com"
}
