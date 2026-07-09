#!/usr/bin/env nu

use std assert

def run [arguments: list<string>] {
  run-external "nu" "scripts/homelab.nu" ...$arguments | complete
}

def main [] {
  let root = (mktemp -d | str trim)
  try {
    let clean = ([$root clean.json] | path join)
    let mounted = ([$root mounted.json] | path join)
    {
      blockdevices: [
        {
          name: "sdz"
          path: "/dev/sdz"
          size: 32000000000
          model: "Test Reader"
          tran: "usb"
          type: "disk"
          mountpoints: [null]
          children: [
            { name: "sdz1", path: "/dev/sdz1", type: "part", mountpoints: [null] }
          ]
        }
      ]
    } | to json | save $clean
    {
      blockdevices: [
        {
          name: "sdz"
          path: "/dev/sdz"
          size: 32000000000
          model: "Test Reader"
          tran: "usb"
          type: "disk"
          mountpoints: [null]
          children: [
            { name: "sdz1", path: "/dev/sdz1", type: "part", mountpoints: ["/media/card"] }
          ]
        }
      ]
    } | to json | save $mounted

    assert equal (run ["flash" "/dev/sdz" "--dry-run" "--metadata-file" $clean]).exit_code 0
    assert not equal (run ["flash" "/dev/sdz1" "--dry-run" "--metadata-file" $clean]).exit_code 0
    assert not equal (run ["flash" "/dev/sdz" "--dry-run" "--metadata-file" $mounted]).exit_code 0

    let deploy_source = (open misc/justfiles/homelab.just)
    assert ($deploy_source | str contains 'target := env("NIXOS_HOST", "")')
    assert ($deploy_source | str contains 'target_host := env("NIXOS_TARGET_HOST", "")')
    assert ($deploy_source | str contains 'nixos-rebuild test --impure --sudo --flake ".#{{ target }}" --target-host "{{ target_host }}"')
    assert ($deploy_source | str contains 'nixos-rebuild switch --impure --sudo --flake ".#{{ target }}" --target-host "{{ target_host }}"')
    assert ($deploy_source | str contains "nu {{ homelab_script }} flash {{ device }}")
    assert ($deploy_source | str contains ".config.system.build.sdImage")
    assert not ($deploy_source | str contains '--use-remote-sudo')

    let homelab_source = (open scripts/homelab.nu)
    assert not ($homelab_source | str contains "jsonschema")
    assert not ($homelab_source | str contains "benchmark-network")

    let storage_source = (open nixos/modules/homelab/storage.nix)
    assert not ($storage_source | str contains "luksFormat")
    assert not ($storage_source | str contains "mkfs")
    assert not ($storage_source | str contains "fsck")
    assert ($storage_source | str contains "cryptsetup open")

    # The homelab-status feature was removed; the policy check also asserts it is
    # gone (nixos/checks/policy/homelab-rpi5.nix). Keep the source tree honest.
    assert not ("nixos/modules/homelab/status.nix" | path exists)
    print "homelab.nu tests passed"
  } finally {
    rm --recursive --force $root
  }
}
