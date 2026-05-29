#!/usr/bin/env nu

use std assert

def run-ok [label: string, command: list<string>] {
  let result = (run-external ...$command | complete)
  assert equal $result.exit_code 0 $"($label) failed; stdout: ($result.stdout); stderr: ($result.stderr)"
  $result
}

def main [] {
  let root = (mktemp -d | str trim)

  try {
    let target = ([$root local] | path join)
    let state = ([$target state.json] | path join)
    let user_secret = ([$target users user user.passwd] | path join)

    mkdir ($state | path dirname)
    mkdir ($user_secret | path dirname)
    {
      schemaVersion: 1
      host: {
        hostname: "existing"
        timezone: "UTC"
      }
      users: [
        {
          name: "user"
          description: "Existing User"
          hashedPasswordFile: "/etc/nixos/local/users/user/user.passwd"
          sources: null
        }
      ]
    } | to json --indent 2 | save --force $state
    "keep-secret" | save --force $user_secret

    run-ok "validate existing local state" [
      "nu"
      "scripts/local/sync.nu"
      "--target"
      $target
      "--apply"
      "--hostname"
      "vm"
      "--timezone"
      "UTC"
      "--user"
      "user"
      "--user-description"
      "User"
    ] | ignore

    assert not ($"($target)/default.nix" | path exists) "local sync must not create a local default.nix shim"
    assert equal (open $state | get host.hostname) "existing"
    assert not ((open $state | columns) | any {|column| $column == "session" })
    assert not ((open $state | columns) | any {|column| $column == "profile" })
    assert equal (open $user_secret | str trim) "keep-secret"
    assert not ($"($target)/users/user.nix" | path exists) "local sync must not copy template users subtree"

    rm --force $state
    run-ok "create local state" [
      "nu"
      "scripts/local/sync.nu"
      "--target"
      $target
      "--apply"
      "--hostname"
      "vm"
      "--timezone"
      "UTC"
      "--user"
      "user"
      "--user-description"
      "User"
      "--dotfiles"
      "/home/user/.dotfiles"
    ] | ignore

    let generated_state = (open $state)
    assert equal $generated_state.schemaVersion 1
    assert not ($generated_state | columns | any {|column| $column == "session" })
    assert not ($generated_state | columns | any {|column| $column == "profile" })
    let generated_user = ($generated_state.users | get 0)
    assert equal $generated_user.isAdmin true
    assert equal $generated_user.extraGroups []
    assert equal $generated_user.shell "nushell"
    assert equal $generated_user.sources.dotfiles "/home/user/.dotfiles"
    assert equal $generated_user.sources.dotfilesModule null
    assert equal $generated_user.sources.dotfilesRoot "/home/user/.dotfiles"
    assert equal $generated_user.sources.links []

    let dotfiles_repo = ([$root dotfiles] | path join)
    let dotfiles_module = ([$root custom home.nix] | path join)
    mkdir ($dotfiles_module | path dirname)
    "{ ... }: { }" | save --force $dotfiles_module
    rm --force $state
    run-ok "create local state with explicit dotfiles module" [
      "nu"
      "scripts/local/sync.nu"
      "--target"
      $target
      "--apply"
      "--hostname"
      "vm"
      "--timezone"
      "UTC"
      "--user"
      "user"
      "--user-description"
      "User"
      "--dotfiles"
      $dotfiles_repo
      "--dotfiles-module"
      $dotfiles_module
    ] | ignore

    let module_user = ((open $state).users | get 0)
    assert equal $module_user.sources.dotfilesModule $dotfiles_module

    rm --force $state
    run-ok "create non-admin local state" [
      "nu"
      "scripts/local/sync.nu"
      "--target"
      $target
      "--apply"
      "--hostname"
      "vm"
      "--timezone"
      "UTC"
      "--user"
      "guest"
      "--user-description"
      "Guest User"
      "--shell"
      "bash"
      "--no-admin"
      "--extra-groups"
      "audio,video"
    ] | ignore

    let guest = ((open $state).users | get 0)
    assert equal $guest.name "guest"
    assert equal $guest.isAdmin false
    assert equal $guest.shell "bash"
    assert ($guest.extraGroups | any {|group| $group == "audio" })
    assert ($guest.extraGroups | any {|group| $group == "video" })

    print "local-sync.nu tests passed"
  } finally {
    rm --recursive --force $root
  }
}
