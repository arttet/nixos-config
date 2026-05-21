#!/usr/bin/env nu

use std assert

use ../install/bootstrap.nu *
use ../install/constants.nu *
use ../install/disko.nu *
use ../common/ui.nu *

def assert-source-ok [path: string] {
  let result = (nu --no-config-file --commands $"source ($path)" | complete)

  assert equal $result.exit_code 0 $"expected ($path) to source cleanly; stderr: ($result.stderr)"
}

def assert-error-message [code: closure, expected: string] {
  let message = (
    try {
      do $code
      ""
    } catch {|error|
      $error.msg
    }
  )

  assert ($message | str contains $expected) $"expected error containing '($expected)', got '($message)'"
}

def test-profile-validation [] {
  validate-profile "default"
  validate-profile "workstation"
  validate-profile "desktop"

  assert-error-message { validate-profile "vm" } "disposable QEMU test target"
  assert-error-message { validate-profile "workstation-gui" } "profile must be one of"
}

def test-user-validation [] {
  validate-user "user"
  validate-user "dev_user"
  validate-user "dev-user"

  assert-error-message { validate-user "root" } "username cannot be root"
  assert-error-message { validate-user "User" } "username must start with"
  assert-error-message { validate-user "1user" } "username must start with"
}

def test-user-description-validation [] {
  validate-user-description "User"
  validate-user-description "Default User"

  assert-error-message { validate-user-description "" } "user description is required"
  assert-error-message { validate-user-description "Default \"User\"" } "user description may contain only"
}

def test-session-validation [] {
  validate-id "system"
  validate-id "system_01"

  assert-error-message { validate-id "" } "session"
  assert-error-message { validate-id "system local" } "session"
  assert-error-message { validate-id "../host" } "session"
}

def test-hostname-derivation [] {
  assert equal (derive-hostname "system" "pc") "system"
  assert equal (derive-hostname "system_local" "pc") "pc"
}

def test-flake-uri [] {
  assert ($"(flake-uri "default")" | str starts-with "path:")
  assert ($"(flake-uri "default")" | str ends-with "#default")
  assert ($"(flake-uri "desktop")" | str ends-with "#desktop")
}

def test-presentation-no-color [] {
  with-env { NO_COLOR: "1", NIX_CONFIG_INSTALL_PLAIN_UI: "1" } {
    assert equal (paint "heading" "Profile") "Profile"
    assert equal (paint "danger" "warning") "warning"
  }
}

def test-plain-ui-rendering [] {
  with-env { NIX_CONFIG_INSTALL_PLAIN_UI: "1", NO_COLOR: "1" } {
    let section = (render-kv-section "NixOS installer" [
      { label: "Target disk", value: "/dev/nvme0n1" }
      { label: "Encryption", value: "LUKS enabled" }
    ])

    assert ($section | str contains "NixOS installer")
    assert ($section | str contains "Target disk")
    assert ($section | str contains "/dev/nvme0n1")
    assert equal (render-step 2 6 "Applying disk layout" "running") "  [2/6] Applying disk layout               … running"
    assert equal (render-step 3 6 "Generating hardware configuration" "ok") "  [3/6] Generating hardware configuration  ✓ ok"
  }
}

def test-password-validation [] {
  validate-password "not-empty"
  assert-error-message { validate-password "" } "password is required"
  assert-error-message { validate-password "   " } "password is required"
}

def test-summary-does-not-print-password-hash-path [] {
  let output = (
    nu --no-config-file --commands "
      use scripts/install/bootstrap.nu *
      print-summary {
        session: 'system'
        profile: 'default'
        user_description: 'User'
        user: 'user'
        password: ''
        password_hash: '$6$hash'
        hostname: 'system'
        timezone: 'UTC'
        disk: '/dev/sda'
        action: 'dry-run'
      }
    " | complete
  )

  assert ($output.stdout | str contains "Password set")
  assert ($output.stdout | str contains "yes")
  assert not ($output.stdout | str contains "user.passwd")
  assert not ($output.stdout | str contains "Password hash")
}

def test-disko-mode-is-current [] {
  assert equal (disko-mode) "destroy,format,mount"

  let source = (open scripts/install/disko.nu)
  assert not ($source | str contains "--mode disko")
}

def write-test-json [path: string, body: record] {
  $body | to json --indent 2 | save --force $path
}

def test-disko-config-disk-validation [] {
  let root = (mktemp -d | str trim)

  try {
    let matching = ([$root matching.json] | path join)
    let mismatched = ([$root mismatched.json] | path join)
    let invalid = ([$root invalid.json] | path join)
    let disk = ([$root disk.img] | path join)
    let other_disk = ([$root other-disk.img] | path join)

    touch $disk
    touch $other_disk

    write-test-json $matching {
      schemaVersion: 1
      disk: { device: $disk }
    }
    write-test-json $mismatched {
      schemaVersion: 1
      disk: { device: $other_disk }
    }
    write-test-json $invalid {
      schemaVersion: 1
      disk: { device: "not-a-dev-path" }
    }

    assert equal (config-disk-devices $matching) [ $disk ]
    validate-config-disk $disk $matching

    assert-error-message { validate-config-disk $disk $mismatched } "does not match confirmed disk"
    assert-error-message { validate-config-disk $disk $invalid } "JSON contract validation failed"
  } finally {
    rm --recursive --force $root
  }
}

def test-disko-config-password-file [] {
  let root = (mktemp -d | str trim)

  try {
    let state = ([$root disko-state.json] | path join)
    let key = ([$root luks.key] | path join)
    let disk = ([$root disk.img] | path join)
    touch $disk

    write-test-json $state {
      schemaVersion: 1
      disk: { device: $disk }
      luks: { passwordFile: $key }
    }

    let result = (
      with-env { NIX_CONFIG_DISKO_STATE: $state } {
        nix eval --impure --file templates/disko/default.nix --apply 'cfg: cfg.disko.devices.disk.workstation.content.partitions.luks.content.passwordFile' | complete
      }
    )
    assert equal $result.exit_code 0 $"expected disko template to evaluate passwordFile; stderr: ($result.stderr)"
    assert ($result.stdout | str contains $key) "expected disko template to include passwordFile from disko-state.json"
  } finally {
    rm --recursive --force $root
  }
}

def test-installer-contract-schemas [] {
  let result = (check-jsonschema --check-metaschema schemas/install-state.v1.schema.json schemas/disko-state.v1.schema.json | complete)
  assert equal $result.exit_code 0 $"JSON schemas must be valid metaschemas; stderr: ($result.stderr)"
}

def test-target-flag-removed [] {
  let source = (open scripts/install/bootstrap.nu)
  assert not ($source | str contains "--target") "installer must not keep deprecated --target before first release"
}

def test-installer-file-permission-contract [] {
  let source = (open scripts/install/bootstrap.nu)

  assert ($source | str contains "def ensure-private-secrets-dir") "expected a dedicated secrets directory helper"
  assert ($source | str contains "chmod 700 $dir") "expected private installer directories to be chmod 700"
  assert ($source | str contains "chmod 700 $persistent_user_dir") "expected target local overlay directory to be chmod 700"
  assert ($source | str contains "install -m 600 /dev/null $path") "expected secret files to be created mode 600"
  assert ($source | str contains "install -m 600 (password-hash-path $state.session) (mounted-target-password-path $state.user)") "expected target password hash to be copied mode 600"
}

def test-installer-preflight-contract [] {
  let source = (open scripts/install/bootstrap.nu)

  assert ($source | str contains "def require-uefi") "expected UEFI pre-flight check"
  assert ($source | str contains '"/sys/firmware/efi" | path exists') "expected UEFI check to inspect efivars path"
  assert ($source | str contains "def ensure-mnt-free") "expected /mnt pre-flight check"
  assert ($source | str contains "findmnt /mnt") "expected /mnt check to use findmnt"
  assert ($source | str contains "def require-network") "expected network pre-flight check"
  assert ($source | str contains "ping -c 1 cache.nixos.org") "expected cache.nixos.org connectivity check"
  assert ($source | str contains "run-preflight-checks $state.session") "expected apply flow to run pre-flight before destructive confirmation"
}

def test-installer-output-logging-contract [] {
  let source = (open scripts/install/bootstrap.nu)

  assert ($source | str contains "def run-logged-stream") "expected helper for captured command output logging"
  assert ($source | str contains "tee -a") "expected stdout and stderr to be logged via tee"
  assert ($source | str contains "run-logged-stream $state.session \"disko\"") "expected disko output logging"
  assert ($source | str contains "run-logged-stream $state.session \"nixos-generate-config\"") "expected nixos-generate-config output logging"
}

assert-source-ok "scripts/install/common.nu"
assert-source-ok "scripts/install/constants.nu"
assert-source-ok "scripts/common/ui.nu"
assert-source-ok "scripts/install/bootstrap.nu"
assert-source-ok "scripts/install/disko.nu"
assert-source-ok "scripts/install/workstation.nu"
assert-source-ok "scripts/local/sync.nu"

test-profile-validation
test-user-validation
test-user-description-validation
test-session-validation
test-hostname-derivation
test-flake-uri
test-presentation-no-color
test-plain-ui-rendering
test-password-validation
test-summary-does-not-print-password-hash-path
test-disko-mode-is-current
test-disko-config-disk-validation
test-disko-config-password-file
test-installer-contract-schemas
test-target-flag-removed
test-installer-file-permission-contract
test-installer-preflight-contract
test-installer-output-logging-contract

print "install.nu tests passed"
