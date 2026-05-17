#!/usr/bin/env nu

use common.nu *
use constants.nu *

# Runtime path helpers are grouped first; stable defaults live in constants.nu.

def ui-rule [] {
  "" | fill --alignment l --character "━" --width (ui-width)
}

def state-root [] {
  $env.NIX_CONFIG_INSTALL_STATE_DIR? | default (join-path [ $env.HOME ".cache" "nixos-config-installer" "state" ])
}

def install-dir [session: string] {
  join-path [ (state-root) $session ]
}

def ensure-private-install-dir [session: string] {
  let dir = (install-dir $session)
  ensure-dir $dir
  chmod 700 $dir
  $dir
}

def overlay-path [session: string] {
  join-path [ (install-dir $session) "user.nix" ]
}

def password-path [session: string] {
  join-path [ (install-dir $session) "user.passwd" ]
}

def target-local-dir [] {
  "/mnt/root/.nix-config-local"
}

def target-password-path [] {
  "/root/.nix-config-local/user.passwd"
}

def mounted-target-password-path [] {
  join-path [ (target-local-dir) "user.passwd" ]
}

def env-path [session: string] {
  join-path [ (install-dir $session) "install.env" ]
}

def hardware-config-path [] {
  "/mnt/etc/nixos/hardware-configuration.nix"
}

def disko-config-path [] {
  join-path [ (temp-root) "workstation-disko.nix" ]
}

export def flake-uri [profile: string] {
  if $profile == "default" {
    $"path:(repo-root)#"
  } else {
    $"path:(repo-root)#($profile)"
  }
}

def prompt-default [label: string, default: string] {
  let prompt = $"(paint prompt $label) [(paint value $default)]: "
  let answer = (input $prompt | str trim)

  if $answer == "" {
    $default
  } else {
    $answer
  }
}

export def no-color [] {
  ($env.NO_COLOR? | default "") != ""
}

export def paint [kind: string, text: string] {
  if (no-color) {
    return $text
  }

  match $kind {
    "logo" => $"(ansi cyan_bold)($text)(ansi reset)"
    "heading" => $"(ansi cyan_bold)($text)(ansi reset)"
    "rule" => $"(ansi blue_dimmed)($text)(ansi reset)"
    "detail" => $"(ansi light_gray_bold)($text)(ansi reset)"
    "label" => $"(ansi blue_bold)($text)(ansi reset)"
    "value" => $"(ansi green_bold)($text)(ansi reset)"
    "prompt" => $"(ansi cyan_bold)($text)(ansi reset)"
    "success" => $"(ansi green_bold)($text)(ansi reset)"
    "warning" => $"(ansi yellow_bold)($text)(ansi reset)"
    "danger" => $"(ansi red_bold)($text)(ansi reset)"
    "muted" => $"(ansi dark_gray_bold)($text)(ansi reset)"
    _ => $text
  }
}

def clear-screen-once [] {
  if ($env.TERM? | default "") != "dumb" {
    print $"(ansi cls)(ansi home)"
  }
}

def print-logo [] {
  print ""
  print (paint logo "    _   ___      ____  ____   __        __         _        _        _   _")
  print (paint logo "   / | / (_)  __/ __ \\/ __/  / /  __   / /__  ____(_)__ ___(_)____ _/ /_(_)__  ___")
  print (paint logo "  /  |/ / / |/ / /_/ /\\ \\   / / |/ /  / / _ \\/ __/ (_-</ _ \\/ __/ _ `/ __/ / _ \\/ _ \\")
  print (paint logo " /_/|_/_/|___/\\____/___/  /_/|___/  /_/\\___/_/ /_/___/_//_/\\__/\\_,_/\\__/_/\\___/_//_/")
  print (paint muted "                         Clean hardware installer")
  print ""
}

def print-section [title: string, details: list<string>] {
  let rule = (paint rule (ui-rule))
  print ""
  print $rule
  print (paint heading $title | fill --alignment center --width (ui-width))
  print $rule
  for detail in $details {
    print $"    (paint detail $detail)"
  }
  print $rule
  print ""
}

def print-kv-section [title: string, rows: list<record<label: string, value: string>>] {
  let rule = (paint rule (ui-rule))
  print ""
  print $rule
  print (paint heading $title | fill --alignment center --width (ui-width))
  print $rule
  for row in $rows {
    let label = ($row.label | fill --alignment l --width (kv-label-width))
    print $"  (paint label $label) : (paint value $row.value)"
  }
  print $rule
  print ""
}

def print-danger-section [title: string, details: list<string>] {
  let rule = (paint danger (ui-rule))
  print ""
  print $rule
  print (paint danger $title | fill --alignment center --width (ui-width))
  print $rule
  for detail in $details {
    print $"    (paint warning $detail)"
  }
  print $rule
  print ""
}

def print-status [message: string] {
  print $"(paint success '==>') ($message)"
}

def print-error-line [message: string] {
  print $"(paint danger 'error:') ($message)"
}

def prompt-validated [label: string, default: string, validator: closure] {
  loop {
    let value = (prompt-default $label $default)

    if $value in [ "q" "r" ] {
      return $value
    }

    let validation = (
      try {
        do $validator $value
        { ok: true, msg: "" }
      } catch {|error|
        { ok: false, msg: $error.msg }
      }
    )

    if $validation.ok {
      return $value
    }

    print-error-line $validation.msg
    print "Enter a valid value, r to go back, or q to quit."
  }
}

def prompt-secret-confirm [label: string, repeat_label: string, validator: closure] {
  loop {
    let password = (input --suppress-output (paint prompt $label))
    print ""

    if $password in [ "q" "r" ] {
      return $password
    }

    let confirmation = (input --suppress-output (paint prompt $repeat_label))
    print ""

    if $confirmation in [ "q" "r" ] {
      return $confirmation
    }

    let validation = (
      try {
        do $validator $password
        { ok: true, msg: "" }
      } catch {|error|
        { ok: false, msg: $error.msg }
      }
    )

    if not $validation.ok {
      print-error-line $validation.msg
      print "Enter a valid password, r to go back, or q to quit."
    } else if $password != $confirmation {
      print-error-line "passwords did not match"
      print "Try again, enter r to go back, or q to quit."
    } else {
      return $password
    }
  }
}

export def validate-id [value: string] {
  if not ($value =~ '^[A-Za-z0-9_-]+$') {
    error make { msg: "session may contain only letters, numbers, underscore, and dash" }
  }
}

export def validate-user [value: string] {
  if $value == "root" {
    error make { msg: "username cannot be root" }
  }

  if not ($value =~ '^[a-z_][a-z0-9_-]*$') {
    error make { msg: "username must start with a lowercase letter or underscore and contain only lowercase letters, numbers, underscores, and dashes" }
  }
}

export def validate-user-description [value: string] {
  if ($value | str trim) == "" {
    error make { msg: "user description is required" }
  }

  if not ($value =~ '^[A-Za-z0-9 ._-]+$') {
    error make { msg: "user description may contain only letters, numbers, spaces, dot, underscore, and dash" }
  }
}

export def validate-password [value: string] {
  if ($value | str trim) == "" {
    error make { msg: "password is required for initial login" }
  }
}

def hash-password [password: string] {
  if (which mkpasswd | length) > 0 {
    let result = ($password | mkpasswd -m sha-512 -s | complete)
    let hash = ($result.stdout | str trim)

    if $result.exit_code == 0 and ($hash | str starts-with '$6$') {
      return $hash
    }
  }

  if (which openssl | length) > 0 {
    let result = ($password | openssl passwd -6 -stdin | complete)
    let hash = ($result.stdout | str trim)

    if $result.exit_code == 0 and ($hash | str starts-with '$6$') {
      return $hash
    }
  }

  error make { msg: "mkpasswd or openssl is required to generate hashedPasswordFile content" }
}

def require-password-hash-tool [] {
  if (which mkpasswd | length) == 0 and (which openssl | length) == 0 {
    error make { msg: "mkpasswd or openssl is required to generate the initial user password hash" }
  }
}

def require-file-permission-tools [] {
  for command in [ "chmod" "install" ] {
    if (which $command | length) == 0 {
      error make { msg: $"($command) is required to create local installer files with restrictive permissions" }
    }
  }
}

def with-password-hash [state: record] {
  let existing_hash = ($state.password_hash? | default "")

  if $existing_hash != "" {
    $state
  } else {
    validate-password $state.password
    $state | upsert password_hash (hash-password $state.password)
  }
}

def require-root [] {
  if (which id | length) == 0 {
    error make { msg: "id command is required to verify root privileges before apply" }
  }

  let uid = (id -u | str trim)
  if $uid != "0" {
    error make { msg: "apply mode must run as root; rerun the installer from a root shell" }
  }
}

export def validate-hostname [value: string] {
  if not ($value =~ '^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$') {
    error make { msg: "hostname must use RFC 1123 labels: letters, digits, and hyphens only" }
  }
}

export def derive-hostname [id: string, current: string] {
  if $id =~ '^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$' {
    $id
  } else {
    $current
  }
}

export def validate-timezone [value: string] {
  if ($value | str trim) == "" {
    error make { msg: "timezone is required" }
  }

  if not ($value =~ '^[A-Za-z0-9_+./-]+$') {
    error make { msg: "timezone contains unsupported characters" }
  }

  let zone_path = (join-path [ "/usr/share/zoneinfo" $value ])
  if ("/usr/share/zoneinfo" | path exists) and not ($zone_path | path exists) {
    error make { msg: $"timezone was not found in /usr/share/zoneinfo: ($value)" }
  }
}

export def validate-profile [value: string] {
  if $value == "vm" {
    error make { msg: "vm is a disposable QEMU test target; use just vm build/run/test instead of the hardware installer" }
  }

  let allowed = (allowed-profiles)
  if not ($value in $allowed) {
    error make { msg: $"profile must be one of: ($allowed | str join ', ')" }
  }
}

def stable-disk-id [disk_path: string] {
  try {
    let matches = (
      glob "/dev/disk/by-id/*"
      | each {|candidate|
        let resolved = (try { readlink -f $candidate | str trim } catch { "" })
        if $resolved == $disk_path and not ($candidate | str contains "-part") {
          $candidate
        } else {
          null
        }
      }
      | compact
    )

    if ($matches | length) > 0 {
      $matches | first
    } else {
      ""
    }
  } catch {
    ""
  }
}

def read-disk-candidates [] {
  if (which lsblk | length) == 0 {
    return []
  }

  let raw = (try {
    lsblk -J -o NAME,SIZE,TYPE,MODEL,SERIAL,MOUNTPOINTS,PATH | from json
  } catch {
    { blockdevices: [] }
  })

  $raw.blockdevices | default [] | where type == "disk" | each {|disk|
    let disk_path = ($disk.path? | default $"/dev/($disk.name)")
    {
      path: $disk_path
      stable_id: (stable-disk-id $disk_path)
      size: ($disk.size? | default "")
      model: ($disk.model? | default "")
      serial: ($disk.serial? | default "")
      mountpoints: (($disk.mountpoints? | default []) | compact | str join ",")
    }
  }
}

def choose-disk [current: string] {
  print-section "Disk Discovery" [
    "The installer reads block devices from lsblk."
    "Review size, model, serial, mountpoints, and stable by-id names."
    "Reference commands: lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL,MOUNTPOINTS"
    "Reference commands: ls -l /dev/disk/by-id/"
  ]

  let disks = (read-disk-candidates)

  if ($disks | length) == 0 {
    print "No lsblk disk candidates were parsed. Enter a disk path manually."
    loop {
      let manual = (prompt-default "Disk device" $current)

      if $manual == "q" {
        exit 0
      }

      if $manual == "r" {
        return "r"
      }

      let validation = (
        try {
          validate-disk $manual
          { ok: true, msg: "" }
        } catch {|error|
          { ok: false, msg: $error.msg }
        }
      )

      if $validation.ok {
        return $manual
      }

      print-error-line $validation.msg
      print "Enter a valid disk path, r to go back, or q to quit."
    }
  }

  print "Available disk candidates:"
  $disks | enumerate | each {|item|
    let n = $item.index + 1
    let disk = $item.item
    let stable = if $disk.stable_id == "" { "no-by-id-match" } else { $disk.stable_id }
    print $"[($n)] ($disk.path)  id=($stable)  ($disk.size)  ($disk.model)  ($disk.serial)  mounts=($disk.mountpoints)"
  }
  print "[m] manual path"
  print "[r] back"
  print "[q] quit"
  print ""

  loop {
    let answer = (input "Select disk: " | str trim)

    if $answer == "q" {
      exit 0
    }

    if $answer == "r" {
      return "r"
    }

    if $answer == "m" {
      loop {
        let manual = (input "Disk device [/dev/disk/by-id/...]: " | str trim)

        if $manual == "q" {
          exit 0
        }

        if $manual == "r" {
          return "r"
        }

        let validation = (
          try {
            validate-disk $manual
            { ok: true, msg: "" }
          } catch {|error|
            { ok: false, msg: $error.msg }
          }
        )

        if $validation.ok {
          return $manual
        }

        print-error-line $validation.msg
        print "Enter a valid disk path, r to go back, or q to quit."
      }
    }

    let index = (try { $answer | into int } catch { 0 })
    if $index >= 1 and $index <= ($disks | length) {
      return (($disks | get ($index - 1)).path)
    }

    print "Choose a listed number, m, r, or q."
  }
}

def write-overlay [state: record] {
  ensure-private-install-dir $state.session | ignore

  let overlay = $"
{ pkgs, lib, ... }:
{
  networking.hostName = lib.mkForce \"($state.hostname)\";
  time.timeZone = lib.mkForce \"($state.timezone)\";

  users.users.\"($state.user)\" = {
    isNormalUser = true;
    description = \"($state.user_description)\";
    shell = pkgs.nushell;
    hashedPasswordFile = \"(target-password-path)\";
    extraGroups = [ \"wheel\" ];
  };
}
"

  $overlay | save --force (overlay-path $state.session)
}

def write-password-file [state: record] {
  ensure-private-install-dir $state.session | ignore

  let path = (password-path $state.session)
  install -m 600 /dev/null $path
  $state.password_hash | save --force $path
  chmod 600 $path
}

def write-env [state: record] {
  let env_file = $"
export NIX_CONFIG_LOCAL_USER=\"(overlay-path $state.session)\"
export NIX_CONFIG_LOCAL_HARDWARE=\"(hardware-config-path)\"
"

  $env_file | save --force (env-path $state.session)
}

export def print-summary [state: record] {
  let password_set = if (($state.password_hash? | default "") != "") or (($state.password? | default "") != "") {
    "yes"
  } else {
    "no"
  }

  print-kv-section "Install Summary" [
    { label: "Session", value: $state.session }
    { label: "Profile", value: $state.profile }
    { label: "User", value: $state.user_description }
    { label: "Username", value: $state.user }
    { label: "Password set", value: $password_set }
    { label: "Hostname", value: $state.hostname }
    { label: "Timezone", value: $state.timezone }
    { label: "Disk", value: $state.disk }
    { label: "Local overlay", value: (overlay-path $state.session) }
    { label: "Install env", value: (env-path $state.session) }
    { label: "Hardware config", value: (hardware-config-path) }
  ]
}

def print-next-commands [state: record] {
  let repo = (repo-root)
  let flake = (flake-uri $state.profile)

  print-section "Generated Files" [
    (overlay-path $state.session)
    (env-path $state.session)
    (disko-config-path)
  ]

  print (paint success "Dry-run complete. No destructive command was run.")
  print ""
  print "To apply after review:"
  print $"  source \"(env-path $state.session)\""
  print $"  nu \"($repo)/scripts/install/disko.nu\" \"($state.disk)\""
  print "  nixos-generate-config --root /mnt"
  print "  test -f /mnt/etc/nixos/hardware-configuration.nix"
  print $"  NIX_CONFIG_LOCAL_USER=\"(overlay-path $state.session)\" \\"
  print $"  NIX_CONFIG_LOCAL_HARDWARE=\"(hardware-config-path)\" \\"
  print $"  nixos-install --impure --flake \"($flake)\""
}

def confirm-disk [disk_device: string] {
  print-danger-section "Destructive Disk Confirmation" [
    $"Disk selected for formatting: ($disk_device)"
    "This will repartition and format the selected disk."
    "Type the exact disk path to continue."
  ]
  let confirmation = (input "Type the exact disk path to continue: " | str trim)

  if $confirmation != $disk_device {
    error make { msg: "disk confirmation did not match; aborting" }
  }
}

def run-apply [state: record] {
  require-root

  let repo = (repo-root)
  let flake = (flake-uri $state.profile)

  confirm-disk $state.disk

  print-status "Applying disk layout..."
  # Disko stays interactive here so cryptsetup can ask for the LUKS passphrase.
  # Capture the exit code immediately before any later command can overwrite it.
  nu $"($repo)/scripts/install/disko.nu" $state.disk --yes --config (disko-config-path)
  let disko_exit_code = $env.LAST_EXIT_CODE
  if $disko_exit_code != 0 {
    error make { msg: $"disko failed with exit code ($disko_exit_code); aborting before hardware generation and nixos-install" }
  }

  print-status "Generating hardware configuration..."
  nixos-generate-config --root /mnt
  let generate_config_exit_code = $env.LAST_EXIT_CODE
  if $generate_config_exit_code != 0 {
    error make { msg: $"nixos-generate-config failed with exit code ($generate_config_exit_code)" }
  }

  if not ((hardware-config-path) | path exists) {
    error make { msg: "hardware configuration was not generated" }
  }

  print-status "Persisting local overlay to target system..."
  let persistent_user_dir = (target-local-dir)
  mkdir $persistent_user_dir
  chmod 700 $persistent_user_dir
  cp (overlay-path $state.session) $"($persistent_user_dir)/user.nix"
  let password_copy = (
    install -m 600 (password-path $state.session) (mounted-target-password-path)
    | complete
  )
  if $password_copy.exit_code != 0 {
    let stderr = ($password_copy.stderr | str trim)
    let detail = if $stderr == "" { "" } else { $": ($stderr)" }
    error make { msg: $"failed to persist password file to target system($detail)" }
  }

  print-status "Installing NixOS..."
  with-env {
    NIX_CONFIG_LOCAL_USER: $"($persistent_user_dir)/user.nix"
    NIX_CONFIG_LOCAL_HARDWARE: (hardware-config-path)
  } {
    nixos-install --impure --flake $flake --no-root-passwd
    let nixos_install_exit_code = $env.LAST_EXIT_CODE
    if $nixos_install_exit_code != 0 {
      error make { msg: $"nixos-install failed with exit code ($nixos_install_exit_code)" }
    }
  }

  print ""
  print-section "Install Complete" [
    "The install command completed."
    "Reboot when ready after reviewing the first boot checks."
  ]
  print (paint heading "Reboot command:")
  print "  reboot"
  print ""
  print (paint heading "First boot checks:")
  print "  test -d /sys/firmware/efi"
  print "  findmnt"
  print "  swapon --show"
  print "  systemctl status NetworkManager"
  print "  doas true"
  print $"  doas nixos-rebuild switch --impure --flake \"($flake)\""
}

def run-wizard [initial: record] {
  mut state = $initial
  mut step = 0

  clear-screen-once
  print-logo
  print-section "Interactive NixOS workstation installer" [
    "This wizard prepares a clean-hardware workstation install."
    "Enter q to quit or r to go back when a prompt allows it."
    "No disk is formatted until the final destructive confirmation."
  ]

  loop {
    if $step == 0 {
      print-section "Session" [
        "Local name for this installer run."
        $"Files are stored under (state-root)/<session>/."
      ]
      let value = (prompt-validated "Session" $state.session {|input| validate-id $input })
      if $value == "q" { exit 0 }
      if $value == "r" { continue }
      let next_hostname = (derive-hostname $value $state.hostname)
      $state = ($state | upsert session $value | upsert hostname $next_hostname)
      $step = 1
    } else if $step == 1 {
      print-section "Profile" [
        "Choose what NixOS system to install on this disk."
        "default installs the graphical workstation target."
        $"Allowed values: ((allowed-profiles) | str join ', ')."
      ]
      let value = (prompt-validated "Profile" $state.profile {|input| validate-profile $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 0 } else {
        $state = ($state | upsert profile $value)
        $step = 2
      }
    } else if $step == 2 {
      print-section "User" [
        "Human-readable account description shown by desktop tools."
        "This can be capitalized, for example User or Default User."
      ]
      let value = (prompt-validated "User" $state.user_description {|input| validate-user-description $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 1 } else {
        $state = ($state | upsert user_description $value)
        $step = 3
      }
    } else if $step == 3 {
      print-section "Username" [
        "Linux login name for the installed system."
        "Use lowercase only, for example user. Do not use User."
      ]
      let value = (prompt-validated "Username" $state.user {|input| validate-user $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 2 } else {
        $state = ($state | upsert user $value)
        $step = 4
      }
    } else if $step == 4 {
      print-section "Password" [
        "Password for the local account on first boot."
        "Input is hidden and must be entered twice."
      ]
      let value = (prompt-secret-confirm "User password: " "Repeat password: " {|input| validate-password $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 3 } else {
        $state = ($state | upsert password $value)
        $step = 5
      }
    } else if $step == 5 {
      print-section "Hostname" [
        "Network name of the installed machine."
        "The default follows the session when it is hostname-safe."
      ]
      let value = (prompt-validated "Hostname" $state.hostname {|input| validate-hostname $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 4 } else {
        $state = ($state | upsert hostname $value)
        $step = 6
      }
    } else if $step == 6 {
      print-section "Timezone" [
        "NixOS timezone for the installed machine."
        "Example: Etc/UTC or Europe/Berlin."
        "Hint: timedatectl list-timezones"
      ]
      let value = (prompt-validated "Timezone" $state.timezone {|input| validate-timezone $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 5 } else {
        $state = ($state | upsert timezone $value)
        $step = 7
      }
    } else if $step == 7 {
      print-section "Disk" [
        "Select the physical disk that will be repartitioned and formatted."
        "Review model, serial, size, and mountpoints before choosing."
      ]
      let value = if $state.disk == "" { choose-disk "" } else { choose-disk $state.disk }
      if $value == "r" { $step = 6 } else {
        validate-disk $value
        $state = ($state | upsert disk $value)
        $step = 8
      }
    } else if $step == 8 {
      print-section "Action" [
        "dry-run writes generated files only."
        "apply starts the destructive install flow after exact disk confirmation."
      ]
      print-summary $state
      print ""
      print $"[(paint label d)] dry-run"
      print $"[(paint danger a)] apply"
      print $"[(paint label r)] back"
      print $"[(paint label q)] quit"
      let prompt = $"(paint prompt 'Action') [(paint value $state.action)]: "
      let value = (input $prompt | str trim)

      if $value == "q" { exit 0 }
      if $value == "r" { $step = 7 } else if $value == "a" or $value == "apply" {
        $state = ($state | upsert action "apply")
        return $state
      } else if $value == "" {
        return $state
      } else {
        $state = ($state | upsert action "dry-run")
        return $state
      }
    }
  }
}

def main [
  --dry-run
  --apply
  --profile: string = ""
  --target: string = ""
  --session: string = ""
  --user-description: string = ""
  --user: string = ""
  --password: string = ""
  --hostname: string = ""
  --timezone: string = ""
  --disk: string = ""
] {
  require-password-hash-tool
  require-file-permission-tools

  if $dry_run and $apply {
    error make { msg: "use either --dry-run or --apply, not both" }
  }

  mut initial = (default-state)

  if $profile != "" and $target != "" {
    error make { msg: "use either --profile or deprecated --target, not both" }
  }

  let selected_profile = if $profile != "" { $profile } else { $target }
  if $selected_profile != "" {
    validate-profile $selected_profile
    $initial = ($initial | upsert profile $selected_profile)
  }

  if $session != "" {
    validate-id $session
    let next_hostname = (derive-hostname $session $initial.hostname)
    $initial = ($initial | upsert session $session | upsert hostname $next_hostname)
  }

  if $user != "" {
    validate-user $user
    $initial = ($initial | upsert user $user)
  }

  if $user_description != "" {
    validate-user-description $user_description
    $initial = ($initial | upsert user_description $user_description)
  }

  if $password != "" {
    validate-password $password
    $initial = ($initial | upsert password $password)
  }

  if $hostname != "" {
    validate-hostname $hostname
    $initial = ($initial | upsert hostname $hostname)
  }

  if $timezone != "" {
    validate-timezone $timezone
    $initial = ($initial | upsert timezone $timezone)
  }

  if $disk != "" {
    validate-disk $disk
    $initial = ($initial | upsert disk $disk)
  }

  if $apply {
    $initial = ($initial | upsert action "apply")
  } else if $dry_run {
    $initial = ($initial | upsert action "dry-run")
  }

  let selected = if $dry_run or $apply {
    if $initial.disk == "" {
      run-wizard $initial
    } else {
      $initial
    }
  } else {
    run-wizard $initial
  }
  let final = (with-password-hash $selected)

  write-overlay $final
  write-password-file $final
  write-env $final
  write-disko-config $final.disk (disko-config-path)
  print-summary $final

  if $final.action == "apply" {
    run-apply $final
  } else {
    print-next-commands $final
  }
}
