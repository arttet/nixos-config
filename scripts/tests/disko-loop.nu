#!/usr/bin/env nu

use std assert

def require-command [name: string] {
  assert ((which $name | length) > 0) $"required command is missing: ($name)"
}

def require-root [] {
  require-command id
  let uid = (id -u | str trim)
  assert equal $uid "0" "disko loop test must run as root"
}

def run-ok [label: string, command: list<string>] {
  let result = (run-external ...$command | complete)
  assert equal $result.exit_code 0 $"($label) failed; stdout: ($result.stdout); stderr: ($result.stderr)"
  $result
}

def require-mnt-free [] {
  let result = (findmnt /mnt | complete)
  assert ($result.exit_code != 0) "/mnt is already mounted; refusing to run destructive disko loop test"
}

def main [] {
  require-root

  for command in [ "cryptsetup" "findmnt" "losetup" "mktemp" "nix" "nu" "truncate" "umount" ] {
    require-command $command
  }
  require-mnt-free

  let root = (mktemp -d | str trim)

  try {
    let image = $"($root)/disk.img"
    let loop_file = $"($root)/loop-device"

    run-ok "create sparse disk image" [ "truncate" "-s" "4G" $image ] | ignore
    let loop_result = (run-ok "attach loop device" [ "losetup" "--find" "--partscan" "--show" $image ])
    let loop_device = ($loop_result.stdout | str trim)
    $loop_device | save --force $loop_file

    try { cryptsetup close cryptroot | ignore }

    with-env { NIX_CONFIG_INSTALL_TMP: $root } {
      run-ok "run disko on loop device" [
        "nu"
        "scripts/install/disko.nu"
        $loop_device
        "--yes"
      ] | ignore
    }

    run-ok "verify root mount" [ "findmnt" "/mnt" ] | ignore
    run-ok "verify boot mount" [ "findmnt" "/mnt/boot" ] | ignore
    run-ok "verify efi mount" [ "findmnt" "/mnt/boot/efi" ] | ignore

    print "disko-loop.nu tests passed"
  } finally {
    try { umount -R /mnt | ignore }
    let loop_file = $"($root)/loop-device"
    let loop_device = if ($loop_file | path exists) { open $loop_file | str trim } else { "" }
    if $loop_device != "" {
      try { cryptsetup close cryptroot | ignore }
      try { losetup -d $loop_device | ignore }
    }
    rm --recursive --force $root
  }
}
