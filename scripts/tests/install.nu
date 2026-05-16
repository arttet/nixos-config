#!/usr/bin/env nu

use std assert

use ../install/bootstrap.nu *

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
  validate-profile "workstation-gui"

  assert-error-message { validate-profile "vm" } "disposable QEMU test target"
  assert-error-message { validate-profile "desktop" } "profile must be one of"
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
  assert ($"(flake-uri "default")" | str ends-with "#")
  assert ($"(flake-uri "workstation-gui")" | str ends-with "#workstation-gui")
}

def test-presentation-no-color [] {
  with-env { NO_COLOR: "1" } {
    assert equal (paint "heading" "Profile") "Profile"
    assert equal (paint "danger" "warning") "warning"
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

assert-source-ok "scripts/install/common.nu"
assert-source-ok "scripts/install/constants.nu"
assert-source-ok "scripts/install/bootstrap.nu"
assert-source-ok "scripts/install/disko.nu"
assert-source-ok "scripts/install/workstation.nu"

test-profile-validation
test-user-validation
test-user-description-validation
test-session-validation
test-hostname-derivation
test-flake-uri
test-presentation-no-color
test-password-validation
test-summary-does-not-print-password-hash-path

print "install.nu tests passed"
