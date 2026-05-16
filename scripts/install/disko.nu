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

  if not $yes {
    confirm-disk $disk_device
  }

  print "Running disko..."
  let repo = (repo-root)
  nix --extra-experimental-features "nix-command flakes" run $"path:($repo)#disko" -- --mode (disko-mode) $config_path
  if $env.LAST_EXIT_CODE != 0 {
    error make { msg: "disko failed" }
  }
}
