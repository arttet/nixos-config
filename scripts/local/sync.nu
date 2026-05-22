#!/usr/bin/env nu

use ../install/bootstrap.nu *
use ../install/common.nu *
use ../install/constants.nu *
use ../common/ui.nu *

def default-target [] {
  "/etc/nixos/local"
}

def template-root [] {
  join-path [ (repo-root) "templates" "local" ]
}

def state-path [target: string] {
  join-path [ $target "state.json" ]
}

def password-path [username: string] {
  $"/etc/nixos/local/users/($username)/($username).passwd"
}

def is-managed-template [path: string] {
  let rel = relative-template-path $path
  $rel == "default.nix" or ($rel | str starts-with "modules/")
}

def relative-template-path [path: string] {
  $path | path relative-to (template-root) | split row '\' | str join '/'
}

def target-path [target: string, template: string] {
  join-path [ $target (relative-template-path $template) ]
}

def managed-templates [] {
  glob (join-path [ (template-root) "**" "*" ])
  | where {|path| ($path | path type) == "file" }
  | where {|path| is-managed-template $path }
}

def file-differs [source: string, target: string] {
  if not ($target | path exists) {
    true
  } else {
    let result = (cmp --silent $source $target | complete)
    $result.exit_code != 0
  }
}

def backup-path [target: string] {
  let stamp = (date now | format date "%Y%m%d%H%M%S")
  $"($target).bak.($stamp)"
}

def prompt-default [label: string, default: string] {
  prompt-text $label $default
}

def prompt-optional [label: string] {
  prompt-text $label ""
}

def normalize-optional-path [value: string] {
  if ($value | str trim) == "" {
    ""
  } else {
    $value | path expand
  }
}

def default-dotfile-links [] {
  [
    ".config/alacritty"
    ".config/bash"
    ".config/fastfetch"
    ".config/git"
    ".config/lazygit"
    ".config/nushell"
    ".config/nvim"
    ".config/shell"
    ".config/starship"
    ".config/tmux"
    ".config/wezterm"
    ".config/yazi"
    ".config/zsh"
    ".zshrc"
  ]
}

def build-sources [
  dotfiles: string
  dotfiles_module: string
  dotfiles_root: string
] {
  let dotfiles_path = normalize-optional-path $dotfiles

  if $dotfiles_path == "" {
    null
  } else {
    let module_path = if ($dotfiles_module | str trim) == "" {
      join-path [ $dotfiles_path "nixos" "home.nix" ]
    } else {
      normalize-optional-path $dotfiles_module
    }
    let root_path = if ($dotfiles_root | str trim) == "" {
      join-path [ $dotfiles_path "dotfiles" ]
    } else {
      normalize-optional-path $dotfiles_root
    }

    {
      dotfiles: $dotfiles_path
      dotfilesModule: $module_path
      dotfilesRoot: $root_path
      links: (default-dotfile-links)
    }
  }
}

def parse-bool [value: string] {
  match ($value | str downcase | str trim) {
    "true" | "yes" | "y" | "1" => true
    "false" | "no" | "n" | "0" => false
    _ => (error make { msg: $"expected boolean value, got: ($value)" })
  }
}

def parse-extra-groups [value: string] {
  if ($value | str trim) == "" {
    []
  } else {
    $value
    | split row ","
    | each {|group| $group | str trim }
    | where {|group| $group != "" }
    | uniq
  }
}

def build-state [
  hostname: string
  timezone: string
  user: string
  user_description: string
  user_shell: string
  is_admin: bool
  extra_groups: string
  dotfiles: string
  dotfiles_module: string
  dotfiles_root: string
] {
  validate-hostname $hostname
  validate-timezone $timezone
  validate-user $user
  validate-user-description $user_description

  {
    schemaVersion: 1
    host: {
      hostname: $hostname
      timezone: $timezone
    }
    users: [
      {
        name: $user
        description: $user_description
        hashedPasswordFile: (password-path $user)
        isAdmin: $is_admin
        extraGroups: (parse-extra-groups $extra_groups)
        shell: $user_shell
        sources: (build-sources $dotfiles $dotfiles_module $dotfiles_root)
      }
    ]
  }
}

def prompt-state [] {
  print-screen "Local Profile Setup" [
    "Create /etc/nixos/local/state.json for this installed system."
    "Leave dotfiles empty to keep Home Manager inactive."
  ]

  let hostname = prompt-default "Hostname" "pc"
  let timezone = prompt-default "Timezone" "UTC"
  let user_description = prompt-default "User description" "User"
  let user = prompt-default "Username" "user"
  let user_shell = prompt-default "Shell" "nushell"
  let is_admin = parse-bool (prompt-default "Admin user" "true")
  let extra_groups = prompt-optional "Extra groups, comma separated"
  let dotfiles = prompt-optional "Dotfiles repository path, empty to disable"
  let dotfiles_module = if $dotfiles == "" {
    ""
  } else {
    prompt-optional "Dotfiles Home Manager module path, empty for <repo>/nixos/home.nix"
  }
  let dotfiles_root = if $dotfiles == "" {
    ""
  } else {
    prompt-optional "Dotfiles root path, empty for <repo>/dotfiles"
  }

  build-state $hostname $timezone $user $user_description $user_shell $is_admin $extra_groups $dotfiles $dotfiles_module $dotfiles_root
}

def ensure-state [
  target_root: string
  apply: bool
  configure: bool
  state: record
] {
  let destination = state-path $target_root
  let should_write = $configure or not ($destination | path exists)

  if not $should_write {
    validate-json (schema-path (platform-state-schema)) $destination
    print $"  (status-text 'ok') state.json"
    return
  }

  if not $apply {
    print $"  (paint warning 'create') state.json"
    return
  }

  ensure-dir ($destination | path dirname)
  if ($destination | path exists) {
    cp $destination (backup-path $destination)
  }
  write-json-contract (schema-path (platform-state-schema)) $destination $state
  print $"  (paint success 'write') state.json"
}

def sync-template [source: string, target_root: string, apply: bool] {
  let destination = (target-path $target_root $source)
  let rel = (relative-template-path $source)
  let action = if not ($destination | path exists) {
    "create"
  } else if (file-differs $source $destination) {
    "update"
  } else {
    "ok"
  }

  let status = match $action {
    "ok" => (status-text "ok")
    "create" => (paint "warning" "create")
    "update" => (paint "warning" "update")
    _ => $action
  }

  print $"  ($status) ($rel)"

  if $apply and $action != "ok" {
    ensure-dir ($destination | path dirname)

    if ($destination | path exists) {
      cp $destination (backup-path $destination)
    }

    cp $source $destination
  }
}

def main [
  --target: string = ""
  --apply
  --configure
  --hostname: string = ""
  --timezone: string = "UTC"
  --user: string = "user"
  --user-description: string = "User"
  --shell: string = "nushell"
  --no-admin
  --extra-groups: string = ""
  --dotfiles: string = ""
  --dotfiles-module: string = ""
  --dotfiles-root: string = ""
  --interactive
  --no-ui
] {
  apply-ui-mode $no_ui

  let target_root = if $target == "" { default-target } else { $target }
  let state_file = state-path $target_root
  let effective_hostname = if $hostname == "" { "pc" } else { $hostname }
  let provided_state = build-state $effective_hostname $timezone $user $user_description $shell (not $no_admin) $extra_groups $dotfiles $dotfiles_module $dotfiles_root
  let next_state = if $interactive and $apply and ($configure or not ($state_file | path exists)) {
    prompt-state
  } else {
    $provided_state
  }

  clear-screen-once
  print-screen "Local Profile Sync" [
    "Sync managed local templates."
    "Preserve state, users, passwords, and secrets."
  ]
  print-kv-section "Sync Context" [
    { label: "Template source", value: (template-root) }
    { label: "Local target", value: $target_root }
    { label: "State file", value: $state_file }
    { label: "Mode", value: (if $apply { "apply" } else { "dry-run" }) }
  ]

  print-step 1 3 "Sync templates" "running"
  for template in (managed-templates) {
    sync-template $template $target_root $apply
  }
  print-step 1 3 "Sync templates" "ok"

  print-step 2 3 "Validate state" "running"
  ensure-state $target_root $apply $configure $next_state
  print-step 2 3 "Validate state" "ok"

  print-step 3 3 "Complete" "ok"

  if not $apply {
    print ""
    print (paint detail "Run with --apply to copy changed templates and create missing state.json.")
  }
}
