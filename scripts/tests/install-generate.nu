#!/usr/bin/env nu

use std assert

def require-command [name: string] {
  assert ((which $name | length) > 0) $"required command is missing: ($name)"
}

def assert-clean-stderr [label: string, stderr: string] {
  let filtered = (
    $stderr
    | lines
    | where {|line| not ($line | str contains "Git tree") }
    | str join "\n"
  )
  assert not ($filtered =~ '(?i)warning:|deprecated') $"unexpected Nix warning during ($label): ($filtered)"
}

def assert-command-ok [label: string, result: record<exit_code: int, stdout: string, stderr: string>] {
  assert equal $result.exit_code 0 $"($label) failed; stderr: ($result.stderr)"
  assert-clean-stderr $label $result.stderr
}

def generated-paths [root: string] {
  {
    state: $"($root)/state/vm"
    temp: $"($root)/tmp"
    overlay: $"($root)/state/vm/user.nix"
    password: $"($root)/state/vm/user.passwd"
    env: $"($root)/state/vm/install.env"
    disko: $"($root)/tmp/workstation-disko.nix"
    hardware: $"($root)/hardware-configuration.nix"
  }
}

def test-disk-path [] {
  "/dev/nixos-config-test-disk"
}

def assert-file [path: string] {
  assert ($path | path exists) $"expected generated file to exist: ($path)"
}

def assert-nix-parses [path: string] {
  let result = (nix-instantiate --parse $path | complete)
  assert-command-ok $"parse ($path)" $result
}

def assert-generated-disko-shape [path: string] {
  let device_check = (
    nix eval --file $path --apply $'cfg: if cfg.disko.devices.disk.workstation.device == "(test-disk-path)" then "ok" else throw "generated disko device was not applied"' | complete
  )
  assert-command-ok "generated disko device shape" $device_check

  let mount_check = (
    nix eval --file $path --apply 'cfg: if cfg.disko.devices.disk.workstation.content.partitions.luks.content.content.subvolumes."@root".mountpoint == "/" then "ok" else throw "generated disko root subvolume is missing"' | complete
  )
  assert-command-ok "generated disko root subvolume shape" $mount_check
}

def write-hardware-stub [path: string] {
  let content = "
{ lib, ... }:
{
  boot.initrd.availableKernelModules = lib.mkDefault [ ];
  boot.kernelModules = lib.mkDefault [ ];
  fileSystems.\"/\" = lib.mkForce {
    device = \"/dev/disk/by-label/nixos\";
    fsType = \"ext4\";
  };
}
"

  $content | save --force $path
}

def assert-generated-config-imports [paths: record] {
  for target in [ "default" "workstation" "workstation-gui" ] {
    let prefix = $"nixosConfigurations.($target)"

    let user_check = (
      with-env {
        NIX_CONFIG_LOCAL_USER: $paths.overlay
        NIX_CONFIG_LOCAL_HARDWARE: $paths.hardware
      } {
        nix eval --impure $".#($prefix).config.users.users.user" --apply 'user: if user.description == "User" && user.hashedPasswordFile == "/root/.nix-config-local/user.passwd" && builtins.elem "wheel" user.extraGroups then "ok" else throw "generated user overlay was not applied correctly"' | complete
      }
    )
    assert-command-ok $"generated user overlay on ($target)" $user_check

    let host_check = (
      with-env {
        NIX_CONFIG_LOCAL_USER: $paths.overlay
        NIX_CONFIG_LOCAL_HARDWARE: $paths.hardware
      } {
        nix eval --impure $".#($prefix).config.networking.hostName" --apply 'host: if host == "vm" then "ok" else throw "generated hostname was not applied"' | complete
      }
    )
    assert-command-ok $"generated hostname overlay on ($target)" $host_check

    let timezone_check = (
      with-env {
        NIX_CONFIG_LOCAL_USER: $paths.overlay
        NIX_CONFIG_LOCAL_HARDWARE: $paths.hardware
      } {
        nix eval --impure $".#($prefix).config.time.timeZone" --apply 'zone: if zone == "UTC" then "ok" else throw "generated timezone was not applied"' | complete
      }
    )
    assert-command-ok $"generated timezone overlay on ($target)" $timezone_check
  }
}

def assert-generated-config-build-plans [paths: record] {
  for target in [ "workstation" "workstation-gui" ] {
    let result = (
      with-env {
        NIX_CONFIG_LOCAL_USER: $paths.overlay
        NIX_CONFIG_LOCAL_HARDWARE: $paths.hardware
      } {
        nix build --impure $".#nixosConfigurations.($target).config.system.build.toplevel" --dry-run --no-link | complete
      }
    )
    assert-command-ok $"generated config build plan for ($target)" $result
  }
}

def main [] {
  for command in [ "mktemp" "nu" "openssl" "install" "chmod" "nix" "nix-instantiate" ] {
    require-command $command
  }

  let root = (mktemp -d | str trim)
  try {
    let paths = (generated-paths $root)
    mkdir $paths.temp
    write-hardware-stub $paths.hardware

    let result = (
      with-env {
        HOME: $root
        NIX_CONFIG_INSTALL_STATE_DIR: $"($root)/state"
        NIX_CONFIG_INSTALL_TMP: $paths.temp
        NO_COLOR: "1"
      } {
        nu scripts/install/bootstrap.nu --dry-run --session vm --profile default --user-description User --user user --password ci-password --hostname vm --timezone UTC --disk (test-disk-path) | complete
      }
    )

    assert equal $result.exit_code 0 $"installer dry-run failed; stderr: ($result.stderr)"

    for path in [ $paths.overlay $paths.password $paths.env $paths.disko ] {
      assert-file $path
    }

    let overlay = (open $paths.overlay)
    assert ($overlay | str contains 'networking.hostName = lib.mkForce "vm";')
    assert ($overlay | str contains 'time.timeZone = lib.mkForce "UTC";')
    assert ($overlay | str contains 'users.users."user"')
    assert ($overlay | str contains 'description = "User";')
    assert ($overlay | str contains 'hashedPasswordFile = "/root/.nix-config-local/user.passwd";')
    assert not ($overlay | str contains "ci-password")

    let password = (open $paths.password | str trim)
    assert ($password | str starts-with '$6$') "expected SHA-512 password hash"
    assert not ($password | str contains "ci-password")

    let password_mode = (ls --long $paths.password | get mode.0)
    assert equal $password_mode "rw-------" "expected generated password file mode 600 (rw-------)"

    let env_file = (open $paths.env)
    assert ($env_file | str contains 'export NIX_CONFIG_LOCAL_USER=')
    assert ($env_file | str contains 'export NIX_CONFIG_LOCAL_HARDWARE="/mnt/etc/nixos/hardware-configuration.nix"')

    let disko = (open $paths.disko)
    assert ($disko | str contains 'disko.devices =')
    assert ($disko | str contains $"device = \"(test-disk-path)\";")
    assert not ($disko | str contains "passwordFile")

    assert-nix-parses $paths.overlay
    assert-nix-parses $paths.disko
    assert-nix-parses $paths.hardware
    assert-generated-disko-shape $paths.disko
    assert-generated-config-imports $paths
    assert-generated-config-build-plans $paths

    print "install-generate.nu tests passed"
  } finally {
    rm --recursive --force $root
  }
}
