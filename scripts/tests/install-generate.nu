#!/usr/bin/env nu

use std assert

def require-command [name: string] {
  assert ((which $name | length) > 0) $"required command is missing: ($name)"
}

def has-command [name: string] {
  (which $name | length) > 0
}

def has-jsonschema-validator [] {
  has-command "jsonschema-cli"
}

def run-jsonschema-validate [schema: string, instance: string] {
  jsonschema-cli validate $schema -i $instance | complete
}

def has-compatible-mkpasswd [] {
  if not (has-command "mkpasswd") {
    return false
  }

  let result = ("ci-password" | mkpasswd -m sha-512 -s | complete)
  $result.exit_code == 0 and (($result.stdout | str trim) | str starts-with '$6$')
}

def has-nix-validation-tools [] {
  (has-command "nix") and (has-jsonschema-validator)
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
    state_dir: $"($root)/state/vm"
    volatile: $"($root)/run"
    platform_state: $"($root)/state/vm/state.json"
    password: $"($root)/run/vm/secrets/user.passwd"
    env: $"($root)/state/vm/install.env"
    disko: $"($root)/run/vm/runtime/disko-state.json"
    hardware: $"($root)/hardware-configuration.nix"
  }
}

def test-disk-path [] {
  "/dev/nixos-config-test-disk"
}

def assert-file [path: string] {
  assert ($path | path exists) $"expected generated file to exist: ($path)"
}

def assert-disko-template-shape [path: string] {
  let device_check = (
    with-env { NIX_CONFIG_DISKO_STATE: $path } {
      nix eval --impure --file templates/disko/default.nix --apply $'cfg: if cfg.disko.devices.disk.workstation.device == "(test-disk-path)" then "ok" else throw "disko state device was not applied"' | complete
    }
  )
  assert-command-ok "generated disko device shape" $device_check

  let mount_check = (
    with-env { NIX_CONFIG_DISKO_STATE: $path } {
      nix eval --impure --file templates/disko/default.nix --apply 'cfg: if cfg.disko.devices.disk.workstation.content.partitions.luks.content.content.subvolumes."@root".mountpoint == "/" then "ok" else throw "disko root subvolume is missing"' | complete
    }
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
  for target in [ "default" "workstation" "desktop" ] {
    let prefix = $"nixosConfigurations.($target)"

    let user_check = (
      with-env {
        NIX_CONFIG_LOCAL_STATE: $paths.platform_state
        NIX_CONFIG_LOCAL_HARDWARE: $paths.hardware
      } {
        nix eval --impure $".#($prefix).config.users.users.user" --apply 'user: if user.description == "User" && user.hashedPasswordFile == "/etc/nixos/local/users/user/user.passwd" && user.shell.pname == "nushell" && builtins.elem "wheel" user.extraGroups then "ok" else throw "generated platform state user was not applied correctly"' | complete
      }
    )
    assert-command-ok $"generated platform state user on ($target)" $user_check

    let host_check = (
      with-env {
        NIX_CONFIG_LOCAL_STATE: $paths.platform_state
        NIX_CONFIG_LOCAL_HARDWARE: $paths.hardware
      } {
        nix eval --impure $".#($prefix).config.networking.hostName" --apply 'host: if host == "vm" then "ok" else throw "generated hostname was not applied"' | complete
      }
    )
    assert-command-ok $"generated hostname from platform state on ($target)" $host_check

    let timezone_check = (
      with-env {
        NIX_CONFIG_LOCAL_STATE: $paths.platform_state
        NIX_CONFIG_LOCAL_HARDWARE: $paths.hardware
      } {
        nix eval --impure $".#($prefix).config.time.timeZone" --apply 'zone: if zone == "UTC" then "ok" else throw "generated timezone was not applied"' | complete
      }
    )
    assert-command-ok $"generated timezone from platform state on ($target)" $timezone_check

    let hm_inactive_check = (
      with-env {
        NIX_CONFIG_LOCAL_STATE: $paths.platform_state
        NIX_CONFIG_LOCAL_HARDWARE: $paths.hardware
      } {
        nix eval --impure $".#($prefix).config.home-manager.users" --apply 'users: if users == {} then "ok" else throw "home-manager users must be inactive while users[].sources is null"' | complete
      }
    )
    assert-command-ok $"generated home-manager inactive on ($target)" $hm_inactive_check
  }
}

def assert-generated-config-build-plans [paths: record] {
  for target in [ "workstation" "desktop" ] {
    let result = (
      with-env {
        NIX_CONFIG_LOCAL_STATE: $paths.platform_state
        NIX_CONFIG_LOCAL_HARDWARE: $paths.hardware
      } {
        nix build --impure $".#nixosConfigurations.($target).config.system.build.toplevel" --dry-run --no-link | complete
      }
    )
    assert-command-ok $"generated config build plan for ($target)" $result
  }
}

def assert-multi-user-state [root: string, hardware: string] {
  let local = $"($root)/multi-user-local"
  let state = $"($local)/state.json"

  mkdir $local
  {
    schemaVersion: 1
    host: {
      hostname: "multi"
      timezone: "UTC"
    }
    users: [
      {
        name: "user"
        description: "User"
        hashedPasswordFile: "/etc/nixos/local/users/user/user.passwd"
        isAdmin: true
        extraGroups: []
        shell: "nushell"
        sources: null
      }
      {
        name: "admin"
        description: "Admin User"
        hashedPasswordFile: "/etc/nixos/local/users/admin/admin.passwd"
        isAdmin: false
        extraGroups: [ "audio" ]
        shell: "bash"
        homeStateVersion: "25.05"
        sources: null
      }
    ]
  } | to json --indent 2 | save --force $state

  let schema_check = (run-jsonschema-validate schemas/platform-state.v1.schema.json $state)
  assert-command-ok "validate multi-user state" $schema_check

  let user_check = (
    with-env {
      NIX_CONFIG_LOCAL_STATE: $state
      NIX_CONFIG_LOCAL_HARDWARE: $hardware
    } {
      nix eval --impure ".#nixosConfigurations.desktop.config.users.users" --apply 'users: if users.user.description == "User" && builtins.elem "wheel" users.user.extraGroups && users.admin.description == "Admin User" && users.admin.shell.pname == "bash-interactive" && users.admin.extraGroups == [ "audio" ] then "ok" else throw "multi-user state was not applied"' | complete
    }
  )
  assert-command-ok "generated multi-user platform state" $user_check
}

def assert-missing-state-error [root: string, hardware: string] {
  let state = $"($root)/missing-state-local/state.json"

  let result = (
    with-env {
      NIX_CONFIG_LOCAL_STATE: $state
      NIX_CONFIG_LOCAL_HARDWARE: $hardware
    } {
      nix eval --impure ".#nixosConfigurations.desktop.config.system.build.toplevel.drvPath" | complete
    }
  )

  assert ($result.exit_code != 0) "missing platform state must fail evaluation"
  assert ($result.stderr | str contains "platform.state.file points to a missing state.json file.") "missing platform state error should be explicit"
}

def assert-platform-state-error [
  root: string
  hardware: string
  name: string
  state: record
  expected: string
] {
  let local = $"($root)/($name)-local"
  let state_file = $"($local)/state.json"

  mkdir $local
  $state | to json --indent 2 | save --force $state_file

  let result = (
    with-env {
      NIX_CONFIG_LOCAL_STATE: $state_file
      NIX_CONFIG_LOCAL_HARDWARE: $hardware
    } {
      nix eval --impure ".#nixosConfigurations.desktop.config.system.build.toplevel.drvPath" | complete
    }
  )

  assert ($result.exit_code != 0) $"($name) platform state must fail evaluation"
  assert ($result.stderr | str contains $expected) $"($name) error should contain '($expected)'; stderr: ($result.stderr)"
}

def assert-platform-state-hardening [root: string, hardware: string] {
  let base_user = {
    name: "user"
    description: "User"
    hashedPasswordFile: "/etc/nixos/local/users/user/user.passwd"
    isAdmin: true
    extraGroups: []
    shell: "nushell"
    sources: null
  }

  assert-platform-state-error $root $hardware "relative-password-file" {
    schemaVersion: 1
    host: {
      hostname: "bad-password"
      timezone: "UTC"
    }
    users: [
      ($base_user | upsert hashedPasswordFile "users/user.passwd")
    ]
  } "platform state users[].hashedPasswordFile must be an absolute path."

  assert-platform-state-error $root $hardware "duplicate-dotfile-links" {
    schemaVersion: 1
    host: {
      hostname: "duplicate-links"
      timezone: "UTC"
    }
    users: [
      ($base_user | upsert sources {
        dotfiles: $root
        dotfilesModule: null
        dotfilesRoot: $root
        links: [ "example/link" "example/link" ]
      })
    ]
  } "platform state users[].sources.links for user must be unique."

  assert-platform-state-error $root $hardware "invalid-dotfile-link" {
    schemaVersion: 1
    host: {
      hostname: "invalid-link"
      timezone: "UTC"
    }
    users: [
      ($base_user | upsert sources {
        dotfiles: $root
        dotfilesModule: null
        dotfilesRoot: $root
        links: [ "../example" ]
      })
    ]
  } "platform state users[].sources.links for user must contain relative dotfile paths without '..'."

  assert-platform-state-error $root $hardware "missing-dotfiles-root" {
    schemaVersion: 1
    host: {
      hostname: "missing-root"
      timezone: "UTC"
    }
    users: [
      ($base_user | upsert sources {
        dotfiles: $root
        dotfilesModule: null
        links: [ "example/link" ]
      })
    ]
  } "platform state users[].sources.dotfilesRoot for user is required when links are configured."
}

def assert-home-state-version [root: string, hardware: string] {
  let local = $"($root)/home-state-version-local"
  let state = $"($local)/state.json"
  let home_module = $"($root)/home-state-version.nix"
  let link_target = $"($root)/example-link"

  mkdir $local
  "{ ... }: { }" | save --force $home_module
  "linked" | save --force $link_target
  {
    schemaVersion: 1
    host: {
      hostname: "home-version"
      timezone: "UTC"
    }
    users: [
      {
        name: "user"
        description: "User"
        hashedPasswordFile: "/etc/nixos/local/users/user/user.passwd"
        isAdmin: true
        extraGroups: []
        shell: "nushell"
        homeStateVersion: "25.05"
        sources: {
          dotfiles: $root
          dotfilesModule: $home_module
          dotfilesRoot: $root
          links: [ "example-link" ]
        }
      }
    ]
  } | to json --indent 2 | save --force $state

  let version_check = (
    with-env {
      NIX_CONFIG_LOCAL_STATE: $state
      NIX_CONFIG_LOCAL_HARDWARE: $hardware
    } {
      nix eval --impure ".#nixosConfigurations.desktop.config.home-manager.users.user.home.stateVersion" | complete
    }
  )
  assert-command-ok "generated home state version" $version_check
  assert equal ($version_check.stdout | str trim) '"25.05"'

  let source_check = (
    with-env {
      NIX_CONFIG_LOCAL_STATE: $state
      NIX_CONFIG_LOCAL_HARDWARE: $hardware
    } {
      nix eval --impure ".#nixosConfigurations.desktop.config.home-manager.users.user.home.file.\"example-link\".source" | complete
    }
  )
  assert-command-ok "generated dotfile link alongside module" $source_check
  assert not ($source_check.stdout | str contains "/nix/store") "dotfile link source must remain out of the Nix store"
  assert ($source_check.stdout | str contains $root) "dotfile link source must point at the mutable dotfiles root"
}

def assert-generated-dotfiles-state [root: string, hardware: string] {
  let dotfiles = $"($root)/dotfiles"
  let module = $"($dotfiles)/home.nix"

  mkdir $dotfiles
  "{ ... }: { home.file.\"nightly-check\".text = \"ok\"; }" | save --force $module

  let result = (
    with-env {
      HOME: $root
      NIX_CONFIG_INSTALL_STATE_DIR: $"($root)/dotfiles-state"
      NIX_CONFIG_INSTALL_VOLATILE_DIR: $"($root)/dotfiles-run"
      NIX_CONFIG_INSTALL_PLAIN_UI: "1"
      NO_COLOR: "1"
    } {
      nu scripts/install/bootstrap.nu --dry-run --session nightly --profile desktop --user-description User --user user --password ci-password --hostname nightly --timezone UTC --disk (test-disk-path) --dotfiles $dotfiles --dotfiles-module $module --dotfiles-links "config/nushell,config/git" | complete
    }
  )

  assert equal $result.exit_code 0 $"installer dry-run with dotfiles failed; stderr: ($result.stderr)"

  let state = $"($root)/dotfiles-state/nightly/state.json"
  let platform_state = (open $state | from json)
  let user = ($platform_state.users | get 0)

  assert equal $platform_state.host.hostname "nightly"
  assert equal $user.sources.dotfiles $dotfiles
  assert equal $user.sources.dotfilesModule $module
  assert equal $user.sources.dotfilesRoot $dotfiles
  assert equal $user.sources.links [ "config/nushell" "config/git" ]

  let schema_check = (run-jsonschema-validate schemas/platform-state.v1.schema.json $state)
  assert-command-ok "validate generated dotfiles platform state" $schema_check

  let hm_check = (
    with-env {
      NIX_CONFIG_LOCAL_STATE: $state
      NIX_CONFIG_LOCAL_HARDWARE: $hardware
    } {
      nix eval --impure ".#nixosConfigurations.desktop.config.home-manager.users.user.home.username" --apply 'name: if name == "user" then "ok" else throw "home-manager user was not generated from dotfiles state"' | complete
    }
  )
  assert-command-ok "generated dotfiles home-manager user" $hm_check
}

def main [] {
  for command in [ "mktemp" "nu" "install" "chmod" "shred" ] {
    require-command $command
  }

  if not (has-compatible-mkpasswd) {
    print "skipping generated installer config dry-run; compatible mkpasswd with sha-512 support is missing"
    return
  }

  let root = (mktemp -d | str trim)
  try {
    let paths = (generated-paths $root)
    write-hardware-stub $paths.hardware

    let result = (
      with-env {
        HOME: $root
        NIX_CONFIG_INSTALL_STATE_DIR: $"($root)/state"
        NIX_CONFIG_INSTALL_VOLATILE_DIR: $paths.volatile
        NIX_CONFIG_INSTALL_PLAIN_UI: "1"
        NO_COLOR: "1"
      } {
        nu scripts/install/bootstrap.nu --dry-run --session vm --profile default --user-description User --user user --password ci-password --hostname vm --timezone UTC --disk (test-disk-path) | complete
      }
    )

    assert equal $result.exit_code 0 $"installer dry-run failed; stderr: ($result.stderr)"

    for path in [ $paths.platform_state $paths.env $paths.disko ] {
      assert-file $path
    }

    assert not ($paths.password | path exists) "dry-run must not persist generated password hash in platform state or volatile secrets"
    assert not ($"($paths.state_dir)/default.nix" | path exists) "installer must not generate a local default.nix shim"

    let platform_state = (open $paths.platform_state)
    assert equal $platform_state.schemaVersion 1
    assert not ($platform_state | columns | any {|column| $column == "session" })
    assert not ($platform_state | columns | any {|column| $column == "profile" })
    assert equal $platform_state.host.hostname "vm"
    assert equal $platform_state.host.timezone "UTC"
    assert equal ($platform_state.users | length) 1
    let platform_user = ($platform_state.users | get 0)
    assert equal $platform_user.name "user"
    assert equal $platform_user.description "User"
    assert equal $platform_user.hashedPasswordFile "/etc/nixos/local/users/user/user.passwd"
    assert equal $platform_user.isAdmin true
    assert equal $platform_user.extraGroups []
    assert equal $platform_user.shell "nushell"
    assert equal $platform_user.sources null

    let env_file = (open $paths.env)
    assert ($env_file | str contains 'export NIX_CONFIG_LOCAL_STATE=')
    assert ($env_file | str contains 'export NIX_CONFIG_LOCAL_HARDWARE="/mnt/etc/nixos/hardware-configuration.nix"')

    let disko_state = (open $paths.disko)
    assert equal $disko_state.schemaVersion 1
    assert equal $disko_state.disk.device (test-disk-path)
    assert not ($disko_state | columns | any {|column| $column == "luks" })

    if (has-nix-validation-tools) {
      let schema_check = (run-jsonschema-validate schemas/platform-state.v1.schema.json $paths.platform_state)
      assert-command-ok "validate generated platform state" $schema_check

      let disko_schema_check = (run-jsonschema-validate schemas/disko-state.v1.schema.json $paths.disko)
      assert-command-ok "validate generated disko state" $disko_schema_check

      assert-disko-template-shape $paths.disko
      assert-generated-config-imports $paths
      assert-generated-config-build-plans $paths
      assert-multi-user-state $root $paths.hardware
      assert-missing-state-error $root $paths.hardware
      assert-platform-state-hardening $root $paths.hardware
      assert-home-state-version $root $paths.hardware
      assert-generated-dotfiles-state $root $paths.hardware
    } else {
      print "skipping Nix-dependent generated config checks; nix or nix-instantiate is missing"
    }

    print "install-generate.nu tests passed"
  } finally {
    rm --recursive --force $root
  }
}
