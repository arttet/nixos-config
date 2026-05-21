#!/usr/bin/env nu

use common.nu *
use constants.nu *

def default-config-path [] {
  join-path [ (temp-root) "disko-state.json" ]
}

def disko-template-path [] {
  join-path [ (repo-root) "templates" "disko" "default.nix" ]
}

def confirm-disk [disk_device: string] {
  print ""
  print "DESTRUCTIVE WARNING"
  print $"Disk selected for formatting: ($disk_device)"
  print "This will repartition and format the selected disk."
  print ""
  let confirmation = (input "Type the exact disk path to continue: " | str trim)

  if $confirmation != $disk_device {
    error make { msg: "disk confirmation did not match; aborting" }
  }
}

export def config-disk-devices [state_path: string] {
  validate-json (schema-path (disko-state-schema)) $state_path

  let result = (
    with-env { NIX_CONFIG_DISKO_STATE: $state_path } {
      nix --extra-experimental-features "nix-command flakes" eval --impure --json --file (disko-template-path) --apply 'f: let cfg = if builtins.isFunction f then f {} else f; in builtins.map (disk: disk.device) (builtins.attrValues (cfg.disko.devices.disk or {}))'
      | complete
    }
  )

  if $result.exit_code != 0 {
    let stderr = ($result.stderr | str trim)
    let detail = if $stderr == "" { "" } else { $": ($stderr)" }
    error make { msg: $"failed to evaluate disko config devices($detail)" }
  }

  $result.stdout | from json
}

export def validate-config-disk [disk_device: string, state_path: string] {
  let devices = (config-disk-devices $state_path)

  if ($devices | length) != 1 {
    error make { msg: $"disko config must define exactly one disk device; found: ($devices | str join ', ')" }
  }

  let config_device = ($devices | first)
  let confirmed_device = (canonical-device-path $disk_device)
  let configured_device = (canonical-device-path $config_device)

  if $configured_device != $confirmed_device {
    error make { msg: $"disko config device ($config_device) does not match confirmed disk ($disk_device)" }
  }
}

export def canonical-device-path [device: string] {
  try {
    $device | path expand --strict
  } catch {
    error make { msg: $"failed to resolve disk device path before wipe: ($device)" }
  }
}

def main [
  --state: string = ""
  --yes
] {
  require-json-schema-tool

  let state_path = if $state == "" { default-config-path } else { $state }

  validate-json (schema-path (disko-state-schema)) $state_path
  let disko_state = (open $state_path)
  let disk_device = $disko_state.disk.device
  validate-disk $disk_device
  validate-config-disk $disk_device $state_path

  if not $yes {
    confirm-disk $disk_device
  }

  print "Running disko..."
  let repo = (repo-root)
  with-env { NIX_CONFIG_DISKO_STATE: $state_path } {
    nix --extra-experimental-features "nix-command flakes" run --impure $"path:($repo)#disko" -- --mode (disko-mode) --yes-wipe-all-disks (disko-template-path)
  }
  let disko_exit_code = $env.LAST_EXIT_CODE
  if $disko_exit_code != 0 {
    error make { msg: $"disko failed with exit code ($disko_exit_code)" }
  }
}
