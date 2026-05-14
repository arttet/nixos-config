#!/usr/bin/env nu

def main [
  disk_device: string
  --overlay: string = ""
  --hardware-config: string = ""
] {
  let home = ($env.HOME? | default "")
  let overlay_path = if $overlay != "" {
    $overlay
  } else if ($env.NIX_CONFIG_LOCAL_USER? | default "") != "" {
    $env.NIX_CONFIG_LOCAL_USER
  } else {
    $"($home)/.nix-config-local/user.nix"
  }

  let hardware_config = if $hardware_config != "" {
    $hardware_config
  } else if ($env.NIX_CONFIG_LOCAL_HARDWARE? | default "") != "" {
    $env.NIX_CONFIG_LOCAL_HARDWARE
  } else {
    "/mnt/etc/nixos/hardware-configuration.nix"
  }

  if ($disk_device | str trim) == "" {
    error make { msg: "disk device is required" }
  }

  if not ($disk_device | str starts-with "/dev/") {
    error make { msg: "disk device must be an absolute /dev path" }
  }

  if not ($overlay_path | path exists) {
    error make { msg: $"missing local overlay: ($overlay_path)" }
  }

  let repo_root = (pwd | str replace --all '\' '/')

  print "Workstation install plan"
  print ""
  print $"Disk device:       ($disk_device)"
  print $"Local overlay:     ($overlay_path)"
  print $"Hardware config:   ($hardware_config)"
  print ""
  print "DESTRUCTIVE WARNING"
  print "The disko step will repartition and format the selected disk device."
  print "Review the device with:"
  print ""
  print "  lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL"
  print ""
  print "No destructive command is executed by this plan."
  print ""
  print "Exact install commands to run manually from the official NixOS ISO:"
  print ""
  print $"  export NIX_CONFIG_LOCAL_USER=($overlay_path)"
  print $"  export NIX_CONFIG_LOCAL_HARDWARE=($hardware_config)"
  print "  cat > /tmp/workstation-disko.nix <<'EOF'"
  print "  { ... }:"
  print "  {"
  print "    imports = ["
  print $"      \(/. + \"($repo_root)/nixos/modules/storage/disko.nix\"\)"
  print "    ];"
  print ""
  print "    platform.storage = {"
  print "      enable = true;"
  print $"      diskDevice = \"($disk_device)\";"
  print "    };"
  print "  }"
  print "  EOF"
  print "  # disko will prompt for the LUKS2 passphrase."
  print "  # Run the remaining commands as root from the official NixOS ISO."
  print "  nix run .#disko -- --mode disko /tmp/workstation-disko.nix"
  print "  nixos-generate-config --root /mnt"
  print "  test -f /mnt/etc/nixos/hardware-configuration.nix"
  print "  nixos-install --impure --flake .#workstation"
}
