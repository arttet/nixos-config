#!/usr/bin/env nu

use common.nu *
use constants.nu *

def default-config-path [] {
  join-path [ (temp-root) "workstation-disko.nix" ]
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

export def config-disk-devices [config_path: string] {
  let result = (
    nix --extra-experimental-features "nix-command flakes" eval --json --file $config_path --apply 'f: let cfg = if builtins.isFunction f then f {} else f; in builtins.map (disk: disk.device) (builtins.attrValues (cfg.disko.devices.disk or {}))'
    | complete
  )

  if $result.exit_code != 0 {
    let stderr = ($result.stderr | str trim)
    let detail = if $stderr == "" { "" } else { $": ($stderr)" }
    error make { msg: $"failed to evaluate disko config devices($detail)" }
  }

  $result.stdout | from json
}

export def validate-config-disk [disk_device: string, config_path: string] {
  let devices = (config-disk-devices $config_path)

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
  disk_device: string
  --yes
  --config: string = ""
] {
  let config_path = if $config == "" { default-config-path } else { $config }
  let config_provided = $config != ""

  validate-disk $disk_device
  if $config_provided {
    if not ($config_path | path exists) {
      error make { msg: $"provided disko config does not exist: ($config_path)" }
    }
  } else {
    write-disko-config $disk_device $config_path
  }

  validate-config-disk $disk_device $config_path

  if not $yes {
    confirm-disk $disk_device
  }

  print "Running disko..."
  let repo = (repo-root)
  nix --extra-experimental-features "nix-command flakes" run $"path:($repo)#disko" -- --mode (disko-mode) --yes-wipe-all-disks $config_path
  if $env.LAST_EXIT_CODE != 0 {
    error make { msg: "disko failed" }
  }
}
