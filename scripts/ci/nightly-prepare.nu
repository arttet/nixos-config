#!/usr/bin/env nu

def repo-root [] {
  git rev-parse --show-toplevel | str trim
}

def join-path [parts: list<string>] {
  $parts | path join
}

def output-path [] {
  $env.GITHUB_OUTPUT? | default ""
}

def write-output [name: string, value: string] {
  let path = output-path

  if $path != "" {
    $"($name)=($value)\n" | save --append $path
  }
}

def optional-absolute [root: string, value: string] {
  if ($value | str trim) == "" {
    ""
  } else {
    join-path [ $root $value ]
  }
}

def main [] {
  let root = repo-root
  let target = join-path [ $root "target" "ci" ]
  let dotfiles = join-path [ $target "dotfiles" ]
  let state_dir = join-path [ $target "state" ]
  let run_dir = join-path [ $target "run" ]
  let home_dir = join-path [ $target "home" ]
  let module = optional-absolute $dotfiles ($env.NIGHTLY_DOTFILES_MODULE? | default "")
  let dotfiles_root = optional-absolute $dotfiles ($env.NIGHTLY_DOTFILES_ROOT? | default "")
  let links = ($env.NIGHTLY_DOTFILES_LINKS? | default "")

  mkdir $target
  mkdir $home_dir

  mut command = [
    "nu"
    "scripts/install/bootstrap.nu"
    "--dry-run"
    "--session"
    "nightly"
    "--profile"
    "desktop"
    "--user-description"
    "User"
    "--user"
    "user"
    "--password"
    "ci-password"
    "--hostname"
    "nightly"
    "--timezone"
    "UTC"
    "--disk"
    "/dev/nixos-config-nightly"
    "--dotfiles"
    $dotfiles
    "--no-ui"
  ]

  if $module != "" {
    $command = ($command | append [ "--dotfiles-module" $module ])
  }

  if $dotfiles_root != "" {
    $command = ($command | append [ "--dotfiles-root" $dotfiles_root ])
  }

  if $links != "" {
    $command = ($command | append [ "--dotfiles-links" $links ])
  }

  let installer_command = $command
  let result = (
    with-env {
      HOME: $home_dir
      NIX_CONFIG_INSTALL_STATE_DIR: $state_dir
      NIX_CONFIG_INSTALL_VOLATILE_DIR: $run_dir
      NIX_CONFIG_INSTALL_PLAIN_UI: "1"
      NO_COLOR: "1"
    } {
      run-external ...$installer_command | complete
    }
  )

  if $result.exit_code != 0 {
    error make { msg: $"nightly installer dry-run failed: ($result.stderr)" }
  }

  let state = join-path [ $state_dir "nightly" "state.json" ]
  write-output "state" $state

  print $"nightly platform state: ($state)"
}
