#!/usr/bin/env nu

def output-path [] {
  $env.GITHUB_OUTPUT? | default ""
}

def write-output [name: string, value: string] {
  let path = output-path

  if $path != "" {
    $"($name)=($value)\n" | save --append $path
  }
}

def require-github-repo [name: string, value: string] {
  if ($value | str trim) == "" {
    error make { msg: $"($name) is required" }
  }

  if not ($value =~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') {
    error make { msg: $"($name) must use owner/repo syntax" }
  }
}

def validate-ref [name: string, value: string] {
  if ($value | str trim) == "" {
    error make { msg: $"($name) must not be empty" }
  }

  if ($value | str contains " ") or ($value | str contains "..") {
    error make { msg: $"($name) contains unsupported characters" }
  }
}

def validate-relative-path [name: string, value: string] {
  if ($value | str trim) == "" {
    return
  }

  if ($value | str starts-with "/") or ($value | str contains "..") {
    error make { msg: $"($name) must be a relative path without '..'" }
  }
}

def validate-links [value: string] {
  if ($value | str trim) == "" {
    return
  }

  for link in ($value | split row "," | each {|item| $item | str trim } | where {|item| $item != "" }) {
    validate-relative-path "NIGHTLY_DOTFILES_LINKS" $link
  }
}

def bool-value [value: string] {
  match ($value | str downcase | str trim) {
    "true" | "1" | "yes" | "y" => "true"
    _ => "false"
  }
}

def main [] {
  let dotfiles_repo = ($env.NIGHTLY_DOTFILES_REPO? | default "" | str trim)
  let dotfiles_ref = ($env.NIGHTLY_DOTFILES_REF? | default "main" | str trim)
  let dotfiles_module = ($env.NIGHTLY_DOTFILES_MODULE? | default "" | str trim)
  let dotfiles_root = ($env.NIGHTLY_DOTFILES_ROOT? | default "" | str trim)
  let dotfiles_links = ($env.NIGHTLY_DOTFILES_LINKS? | default "" | str trim)
  let deploy = bool-value ($env.NIGHTLY_DEPLOY? | default "false")
  let event_name = ($env.GITHUB_EVENT_NAME? | default "")

  require-github-repo "NIGHTLY_DOTFILES_REPO" $dotfiles_repo
  validate-ref "NIGHTLY_DOTFILES_REF" $dotfiles_ref
  validate-relative-path "NIGHTLY_DOTFILES_MODULE" $dotfiles_module
  validate-relative-path "NIGHTLY_DOTFILES_ROOT" $dotfiles_root
  validate-links $dotfiles_links

  if $deploy == "true" and $event_name != "workflow_dispatch" {
    error make { msg: "deploy=true is only valid for workflow_dispatch runs" }
  }

  write-output "dotfiles_repo" $dotfiles_repo
  write-output "dotfiles_ref" $dotfiles_ref
  write-output "dotfiles_module" $dotfiles_module
  write-output "dotfiles_root" $dotfiles_root
  write-output "dotfiles_links" $dotfiles_links
  write-output "deploy" $deploy

  print "nightly preflight passed"
}
