#!/usr/bin/env nu

use common.nu *
use constants.nu *
use ../common/ui.nu *

# Runtime path helpers are grouped first; stable defaults live in constants.nu.

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

def platform-state-path [session: string] {
  join-path [ (install-dir $session) "state.json" ]
}

def volatile-root [] {
  $env.NIX_CONFIG_INSTALL_VOLATILE_DIR? | default "/run/nixos-config-installer"
}

def runtime-dir [session: string] {
  join-path [ (volatile-root) $session "runtime" ]
}

def secrets-dir [session: string] {
  join-path [ (volatile-root) $session "secrets" ]
}

def ensure-private-runtime-dir [session: string] {
  let dir = (runtime-dir $session)
  ensure-dir $dir
  chmod 700 $dir
  $dir
}

def ensure-private-secrets-dir [session: string] {
  let dir = (secrets-dir $session)
  ensure-dir $dir
  chmod 700 $dir
  $dir
}

def remove-secret-file [path: string] {
  if ($path | path exists) {
    let result = (shred -u -z $path | complete)
    if $result.exit_code != 0 {
      let stderr = ($result.stderr | str trim)
      let detail = if $stderr == "" { "" } else { $": ($stderr)" }
      error make { msg: $"failed to shred secret file ($path) with exit code ($result.exit_code)($detail)" }
    }
  }
}

def cleanup-secrets-dir [session: string] {
  let dir = (secrets-dir $session)
  if ($dir | path exists) {
    ls $dir | each {|file|
      remove-secret-file $file.name
    }
    rm --recursive --force $dir
  }
}

def cleanup-volatile-session [session: string] {
  let dir = (join-path [ (volatile-root) $session ])
  if ($dir | path exists) {
    cleanup-secrets-dir $session
    rm --recursive --force $dir
  }
}

def target-local-dir [] {
  "/mnt/etc/nixos/local"
}

def target-password-path [username: string] {
  $"/etc/nixos/local/users/($username)/($username).passwd"
}

def mounted-target-password-path [username: string] {
  join-path [ (target-local-dir) "users" $username $"($username).passwd" ]
}

def env-path [session: string] {
  join-path [ (install-dir $session) "install.env" ]
}

def hardware-config-path [] {
  "/mnt/etc/nixos/hardware-configuration.nix"
}

def disko-state-path [session: string] {
  join-path [ (runtime-dir $session) "disko-state.json" ]
}

def luks-password-path [session: string] {
  join-path [ (secrets-dir $session) "luks.passwd" ]
}

def password-hash-path [session: string] {
  join-path [ (secrets-dir $session) "user.passwd" ]
}

def install-log-path [session: string] {
  join-path [ (runtime-dir $session) "install.log" ]
}

export def flake-uri [profile: string] {
  $"path:(repo-root)#($profile)"
}

def prompt-default [label: string, default: string] {
  prompt-text $label $default
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
    let password = (prompt-secret $label)

    if $password in [ "q" "r" ] {
      return $password
    }

    let confirmation = (prompt-secret $repeat_label)

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
  let result = ($password | mkpasswd -m sha-512 -s | complete)
  let hash = ($result.stdout | str trim)

  if $result.exit_code == 0 and ($hash | str starts-with '$6$') {
    return $hash
  }

  let stderr = ($result.stderr | str trim)
  let detail = if $stderr == "" { "" } else { $": ($stderr)" }
  error make { msg: $"mkpasswd failed to generate hashedPasswordFile content with exit code ($result.exit_code)($detail)" }
}

def require-password-hash-tool [] {
  if (which mkpasswd | length) == 0 {
    error make { msg: "mkpasswd is required to generate the initial user password hash" }
  }
}

def require-file-permission-tools [] {
  for command in [ "chmod" "install" "shred" ] {
    if (which $command | length) == 0 {
      error make { msg: $"($command) is required to create local installer files with restrictive permissions" }
    }
  }
}

def require-apply-tools [] {
  for command in [ "bash" "findmnt" "nixos-generate-config" "nixos-install" "ping" "swapoff" "tee" "umount" ] {
    if (which $command | length) == 0 {
      error make { msg: $"($command) is required before apply mode can safely continue" }
    }
  }
}

def require-uefi [] {
  if not ("/sys/firmware/efi" | path exists) {
    error make { msg: "system booted in Legacy BIOS mode, but this installer requires UEFI; reboot the live USB in UEFI mode" }
  }
}

def ensure-mnt-free [] {
  let result = (findmnt /mnt | complete)
  if $result.exit_code == 0 {
    print $"  (paint warning 'Unmounting existing /mnt from previous run...')"
    let umount_result = (umount -R /mnt | complete)
    if $umount_result.exit_code != 0 {
      let stderr = ($umount_result.stderr | str trim)
      let detail = if $stderr == "" { "" } else { $": ($stderr)" }
      error make { msg: $"failed to unmount /mnt automatically; unmount it manually before running the installer($detail)" }
    }
  }
}

def require-network [] {
  let result = (ping -c 1 cache.nixos.org | complete)
  if $result.exit_code != 0 {
    error make { msg: "cannot reach cache.nixos.org; check network before formatting the disk" }
  }
}

def run-preflight-checks [session: string] {
  print ""
  print (paint heading "Pre-flight Checks")
  print $"  (paint detail 'Validating requirements before applying destructive changes.')"
  append-install-log $session "PREFLIGHT start"

  print-step 1 4 "Checking UEFI boot mode" "running"
  require-uefi
  append-install-log $session "PREFLIGHT uefi=ok"
  print-step 1 4 "Checking UEFI boot mode" "ok"

  print-step 2 4 "Checking installer commands" "running"
  require-apply-tools
  append-install-log $session "PREFLIGHT commands=ok"
  print-step 2 4 "Checking installer commands" "ok"

  print-step 3 4 "Checking /mnt is free" "running"
  ensure-mnt-free
  append-install-log $session "PREFLIGHT mnt=free"
  print-step 3 4 "Checking /mnt is free" "ok"

  print-step 4 4 "Checking network" "running"
  require-network
  append-install-log $session "PREFLIGHT network=ok target=cache.nixos.org"
  print-step 4 4 "Checking network" "ok"
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

def normalize-optional-path [value: string] {
  if ($value | str trim) == "" {
    ""
  } else {
    $value | path expand
  }
}

def parse-dotfiles-links [value: string] {
  if ($value | str trim) == "" {
    []
  } else {
    $value
    | split row ","
    | each {|link| $link | str trim }
    | where {|link| $link != "" }
    | uniq
  }
}

def validate-dotfiles-link [link: string] {
  if ($link | str starts-with "/") or ($link | str contains "..") {
    error make { msg: $"dotfiles link must be a relative path without '..': ($link)" }
  }
}

def build-sources [state: record] {
  let dotfiles = normalize-optional-path ($state.dotfiles? | default "")

  if $dotfiles == "" {
    null
  } else {
    let module = normalize-optional-path ($state.dotfiles_module? | default "")
    let root = normalize-optional-path ($state.dotfiles_root? | default "")
    let links = parse-dotfiles-links ($state.dotfiles_links? | default "")

    for link in $links {
      validate-dotfiles-link $link
    }

    {
      dotfiles: $dotfiles
      dotfilesModule: (if $module == "" { null } else { $module })
      dotfilesRoot: (if $root == "" { $dotfiles } else { $root })
      links: $links
    }
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

def choose-disk [state: record] {
  let current = $state.disk
  let disks = (read-disk-candidates)

  if ($disks | length) == 0 {
    loop {
      wizard-screen $state 8 "Disk" [
        "No lsblk disk candidates were parsed."
        "Enter a disk path manually, preferably /dev/disk/by-id/..."
      ]
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

  loop {
    let options = (
      $disks | enumerate | each {|item|
        let n = $item.index + 1
        let disk = $item.item
        let stable = if $disk.stable_id == "" { "no-by-id-match" } else { $disk.stable_id }
        $"($n). ($disk.path)  ($disk.size)  ($disk.model)  ($disk.serial)  id=($stable)"
      } | append [ "m  manual path" "r  back" "q  quit" ]
    )
    wizard-screen $state 8 "Disk" (
      [
        "Select the physical disk that will be repartitioned and formatted."
        "Review model, serial, size, and stable by-id names before choosing."
        ""
      ] | append $options
    )
    let selected = (prompt-choice "Select disk" $options)
    let answer = if ($selected | str trim) == "" {
      ""
    } else {
      ($selected | split row " " | first | str trim | str replace --regex '[.]$' '')
    }

    if $answer == "q" {
      exit 0
    }

    if $answer == "r" {
      return "r"
    }

    if $answer == "m" {
      loop {
        wizard-screen $state 8 "Manual disk path" [
          "Enter the target disk device."
          "Prefer stable paths under /dev/disk/by-id/."
        ]
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

def disko-template-path [] {
  join-path [ (repo-root) "templates" "disko" "default.nix" ]
}

def platform-state [state: record] {
  {
    schemaVersion: 1
    host: {
      hostname: $state.hostname
      timezone: $state.timezone
    }
    users: [
      {
        name: $state.user
        description: $state.user_description
        hashedPasswordFile: (target-password-path $state.user)
        isAdmin: true
        extraGroups: []
        shell: "nushell"
        sources: (build-sources $state)
      }
    ]
  }
}

def disko-state [
  state: record
  --luks-password-file: string = ""
] {
  let base = {
    schemaVersion: 1
    disk: {
      device: $state.disk
    }
  }

  if $luks_password_file == "" {
    $base
  } else {
    $base | upsert luks {
      passwordFile: $luks_password_file
    }
  }
}

def write-platform-state [state: record] {
  ensure-private-install-dir $state.session | ignore
  write-json-contract (schema-path (platform-state-schema)) (platform-state-path $state.session) (platform-state $state)
}

def write-disko-state [
  state: record
  --luks-password-file: string = ""
] {
  write-json-contract (schema-path (disko-state-schema)) (disko-state-path $state.session) (disko-state $state --luks-password-file $luks_password_file)
}

def write-password-file [state: record] {
  ensure-private-secrets-dir $state.session | ignore

  let path = (password-hash-path $state.session)
  install -m 600 /dev/null $path
  $state.password_hash | save --force $path
  chmod 600 $path
}

def write-luks-password-file [session: string, passphrase: string] {
  ensure-private-secrets-dir $session | ignore
  let path = (luks-password-path $session)
  install -m 600 /dev/null $path
  $passphrase | save --force $path
  chmod 600 $path
}

def append-install-log [session: string, message: string] {
  ensure-private-runtime-dir $session | ignore
  let line = $"(date now | format date '%Y-%m-%dT%H:%M:%S%z')  ($message)\n"
  $line | save --append (install-log-path $session)
}

def log-command-start [session: string, command: string] {
  append-install-log $session $"START command=($command)"
}

def log-command-exit [session: string, command: string, exit_code: int] {
  append-install-log $session $"EXIT code=($exit_code) command=($command)"
}

def run-logged-stream [session: string, command_label: string, command: string] {
  log-command-start $session $command_label
  let log_path = (install-log-path $session)
  bash -c $"set -o pipefail; ($command) 2>&1 | tee -a '($log_path)'"
  let exit_code = $env.LAST_EXIT_CODE
  log-command-exit $session $command_label $exit_code
  $exit_code
}

def disable-active-swap [session: string] {
  let command = "swapoff -a"
  log-command-start $session $command
  let result = (swapoff -a | complete)
  log-command-exit $session $command $result.exit_code

  if $result.exit_code != 0 {
    let stderr = ($result.stderr | str trim)
    let detail = if $stderr == "" { "continuing; no active swap may be present" } else { $stderr }
    append-install-log $session $"WARN swapoff=($detail)"
    print $"  (paint warning 'swapoff warning:') ($detail)"
  }
}

def write-env [state: record] {
  let env_file = $"
export NIX_CONFIG_LOCAL_STATE=\"(platform-state-path $state.session)\"
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
    { label: "Disk", value: $state.disk }
    { label: "Password set", value: $password_set }
  ]

  print-kv-section "Platform State" [
    { label: "User", value: $state.user_description }
    { label: "Username", value: $state.user }
    { label: "Hostname", value: $state.hostname }
    { label: "Timezone", value: $state.timezone }
    { label: "Platform state", value: (platform-state-path $state.session) }
    { label: "Hardware config", value: (hardware-config-path) }
  ]

  print-kv-section "Installer Runtime" [
    { label: "Install env", value: (env-path $state.session) }
  ]
}

def print-next-commands [state: record] {
  let repo = (repo-root)
  let flake = (flake-uri $state.profile)

  print-section "Generated Runtime Files" [
    (platform-state-path $state.session)
    (env-path $state.session)
    (disko-state-path $state.session)
  ]

  print (paint success "Dry-run complete. No destructive command was run.")
  print ""
  print "To apply this reviewed runtime state:"
  print $"  source \"(env-path $state.session)\""
  print $"  nu \"($repo)/scripts/install/disko.nu\" --state \"(disko-state-path $state.session)\""
  print "  nixos-generate-config --root /mnt"
  print "  test -f /mnt/etc/nixos/hardware-configuration.nix"
  print $"  NIX_CONFIG_LOCAL_STATE=\"(platform-state-path $state.session)\" \\"
  print $"  NIX_CONFIG_LOCAL_HARDWARE=\"(hardware-config-path)\" \\"
  print $"  nixos-install --impure --flake \"($flake)\""
}

def confirm-disk [disk_device: string] {
  print-danger-section "Destructive Disk Confirmation" [
    $"Disk selected for formatting: ($disk_device)"
    "This will repartition and format the selected disk."
    "Type the exact disk path to continue."
  ]

  loop {
    let confirmation = (input "> Type the exact disk path to continue (or 'q' to quit): " | str trim)
    if $confirmation == "q" {
      exit 0
    }
    if $confirmation == $disk_device {
      return
    }
    print-error-line "Disk confirmation did not match."
  }
}

def print-apply-plan [state: record] {
  print-kv-section "NixOS installer" [
    { label: "Target disk", value: $state.disk }
    { label: "Encryption", value: "LUKS enabled" }
    { label: "Bootloader", value: "GRUB" }
    { label: "Host profile", value: $state.profile }
    { label: "Local user", value: $state.user }
  ]
}

def masked-status [value: string] {
  if $value == "" { "not set" } else { "set" }
}

def wizard-rows [state: record, step: int, title: string, details: list<string>] {
  let password_status = (masked-status ($state.password? | default ""))
  let disk_value = if $state.disk == "" { "not selected" } else { $state.disk }
  let rows = [
    $"Step                  ($step)/9"
    $"Session               ($state.session)"
    $"Profile               ($state.profile)"
    $"User                  ($state.user_description)"
    $"Username              ($state.user)"
    $"Password              ($password_status)"
    $"Hostname              ($state.hostname)"
    $"Timezone              ($state.timezone)"
    $"Disk                  ($disk_value)"
    $"Action                ($state.action)"
    ""
    $title
    ""
  ]

  $rows | append $details | append [
    ""
    "Enter accepts the shown default. Type r to go back or q to quit when available."
  ]
}

def wizard-screen [state: record, step: int, title: string, details: list<string>] {
  clear-screen-once
  print-screen "NixOS installer" (wizard-rows $state $step $title $details)
  print ""
}

def confirm-command [title: string, description: string, command: string] {
  print ""
  print (paint heading $title)
  print $"  (paint detail $description)"
  print ""
  print $"  (paint warning $command)"
  print ""

  loop {
    let answer = (input "> Run this command? [Y/q]: " | str trim | str downcase)
    if $answer in [ "y" "yes" "" ] {
      return
    }
    if $answer in [ "q" "quit" ] {
      exit 0
    }
    print-error-line "Please enter 'y' or press Enter to continue, or 'q' to quit."
  }
}

def prompt-luks-passphrase [] {
  print ""
  print (paint heading "Disk Encryption")
  print $"  (paint detail 'Passphrase for the encrypted root container.')"
  print $"  (paint detail 'This is separate from the local user login password.')"
  print ""

  loop {
    let value = (prompt-secret-confirm "LUKS passphrase: " "Repeat LUKS passphrase: " {|input| validate-password $input })
    if $value == "q" {
      exit 0
    }

    if $value == "r" {
      print-error-line "cannot go back from apply-time LUKS prompt; please enter a valid password or 'q' to quit."
      continue
    }

    return $value
  }
}

def run-apply [state: record] {
  require-root

  let repo = (repo-root)
  let flake = (flake-uri $state.profile)
  let disko_state = (disko-state-path $state.session)
  let luks_password = (luks-password-path $state.session)

  let disko_command = $"nu \"($repo)/scripts/install/disko.nu\" --yes --state \"($disko_state)\""
  let generate_config_command = "nixos-generate-config --root /mnt"

  let persistent_user_dir = (target-local-dir)
  let persistent_users_dir = (join-path [ $persistent_user_dir "users" ])
  let persistent_user_secret_dir = (join-path [ $persistent_users_dir $state.user ])
  let persistence_command = $"mkdir ($persistent_user_dir)\ncp .../state.json ($persistent_user_dir)/\ninstall -m 600 .../($state.user).passwd ($persistent_user_secret_dir)/"

  let install_command = $"NIX_CONFIG_LOCAL_STATE=\"($persistent_user_dir)/state.json\" NIX_CONFIG_LOCAL_HARDWARE=\"(hardware-config-path)\" nixos-install --impure --flake \"($flake)\" --no-root-passwd"

  cleanup-volatile-session $state.session
  ensure-private-runtime-dir $state.session | ignore
  append-install-log $state.session $"START session=($state.session) profile=($state.profile) disk=($state.disk)"

  clear-screen-once
  print-apply-plan $state

  run-preflight-checks $state.session
  confirm-disk $state.disk
  disable-active-swap $state.session

  confirm-command "Phase 1: Disk Layout" "Applies disko configuration and encrypts the drive." $disko_command

  print-step 1 6 "Preparing encryption" "running"
  try {
    let luks_passphrase = (prompt-luks-passphrase)
    write-luks-password-file $state.session $luks_passphrase
    write-password-file $state
    write-disko-state $state --luks-password-file $luks_password
    append-install-log $state.session $"PREPARED disko_state=($disko_state) luks_password_file=($luks_password)"
  } catch {|error|
    cleanup-secrets-dir $state.session
    print-step 1 6 "Preparing encryption" "failed"
    error make { msg: $error.msg }
  }
  print-step 1 6 "Preparing encryption" "ok"

  print-step 2 6 "Applying disk layout" "running"
  let disko_exit_code = (run-logged-stream $state.session "disko" $disko_command)
  remove-secret-file $luks_password

  if $disko_exit_code != 0 {
    print-step 2 6 "Applying disk layout" "failed"
    cleanup-secrets-dir $state.session
    error make { msg: $"disko failed with exit code ($disko_exit_code); aborting before hardware generation and nixos-install" }
  }
  print-step 2 6 "Applying disk layout" "ok"

  confirm-command "Phase 2: Hardware Config" "Generates NixOS hardware profile for the target machine." $generate_config_command
  print-step 3 6 "Generating hardware configuration" "running"
  let generate_config_exit_code = (run-logged-stream $state.session "nixos-generate-config" $generate_config_command)
  if $generate_config_exit_code != 0 {
    print-step 3 6 "Generating hardware configuration" "failed"
    cleanup-secrets-dir $state.session
    error make { msg: $"nixos-generate-config failed with exit code ($generate_config_exit_code)" }
  }
  print-step 3 6 "Generating hardware configuration" "ok"

  if not ((hardware-config-path) | path exists) {
    cleanup-secrets-dir $state.session
    error make { msg: "hardware configuration was not generated" }
  }

  confirm-command "Phase 3: Persistence" "Copies the local platform state and password to the target." $persistence_command
  print-step 4 6 "Persisting local platform state" "running"
  mkdir $persistent_user_dir
  mkdir $persistent_users_dir
  mkdir $persistent_user_secret_dir
  chmod 700 $persistent_user_dir
  chmod 700 $persistent_users_dir
  chmod 700 $persistent_user_secret_dir
  cp (platform-state-path $state.session) $"($persistent_user_dir)/state.json"
  let password_copy = (
    install -m 600 (password-hash-path $state.session) (mounted-target-password-path $state.user)
    | complete
  )
  if $password_copy.exit_code != 0 {
    let stderr = ($password_copy.stderr | str trim)
    let detail = if $stderr == "" { "" } else { $": ($stderr)" }
    append-install-log $state.session $"FAILED persist-password exit_code=($password_copy.exit_code)"
    print-step 4 6 "Persisting local platform state" "failed"
    cleanup-secrets-dir $state.session
    error make { msg: $"failed to persist password file to target system($detail)" }
  }
  if not ((mounted-target-password-path $state.user) | path exists) {
    print-step 4 6 "Persisting local platform state" "failed"
    cleanup-secrets-dir $state.session
    error make { msg: $"persisted password file is missing from target system: (mounted-target-password-path $state.user)" }
  }
  append-install-log $state.session $"PERSISTED platform_state=($persistent_user_dir)/state.json password_file=(mounted-target-password-path $state.user)"
  cleanup-secrets-dir $state.session
  print-step 4 6 "Persisting local platform state" "ok"

  confirm-command "Phase 4: NixOS Install" "Builds and installs the NixOS system." $install_command
  print-step 5 6 "Installing NixOS" "running"
  with-env {
    NIX_CONFIG_LOCAL_STATE: $"($persistent_user_dir)/state.json"
    NIX_CONFIG_LOCAL_HARDWARE: (hardware-config-path)
  } {
    let nixos_install_exit_code = (run-logged-stream $state.session "nixos-install" $install_command)
    if $nixos_install_exit_code != 0 {
      print-step 5 6 "Installing NixOS" "failed"
      error make { msg: $"nixos-install failed with exit code ($nixos_install_exit_code)" }
    }
  }
  print-step 5 6 "Installing NixOS" "ok"
  print-step 6 6 "Install complete" "ok"
  append-install-log $state.session "COMPLETE"

  print ""
  print (paint success "Install Complete")
  print $"  (paint detail 'The install command completed.')"
  print $"  (paint detail $'Install log: (install-log-path $state.session)')"

  print-section "Next Step" [
    "reboot"
  ]
}

def run-wizard [initial: record] {
  mut state = $initial
  mut step = 0

  clear-screen-once

  loop {
    if $step == 0 {
      wizard-screen $state 1 "Session" [
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
      wizard-screen $state 2 "Profile" [
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
      wizard-screen $state 3 "User" [
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
      wizard-screen $state 4 "Username" [
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
      wizard-screen $state 5 "Password" [
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
      wizard-screen $state 6 "Hostname" [
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
      wizard-screen $state 7 "Timezone" [
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
      wizard-screen $state 8 "Disk" [
        "Select the physical disk that will be repartitioned and formatted."
        "Review model, serial, size, and mountpoints before choosing."
      ]
      let value = (choose-disk $state)
      if $value == "r" { $step = 6 } else {
        validate-disk $value
        $state = ($state | upsert disk $value)
        $step = 8
      }
    } else if $step == 8 {
      wizard-screen $state 9 "Action" [
        "dry-run writes generated files only."
        "apply starts the destructive install flow after exact disk confirmation."
        ""
        "d  dry-run"
        "a  apply"
        "r  back"
        "q  quit"
      ]
      let selected_action = (prompt-choice $"Action [($state.action)]" [
        "d  dry-run"
        "a  apply"
        "r  back"
        "q  quit"
      ])
      let value = if ($selected_action | str trim) == "" {
        ""
      } else {
        ($selected_action | split row " " | first | str trim)
      }

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
  --session: string = ""
  --user-description: string = ""
  --user: string = ""
  --password: string = ""
  --hostname: string = ""
  --timezone: string = ""
  --disk: string = ""
  --dotfiles: string = ""
  --dotfiles-module: string = ""
  --dotfiles-root: string = ""
  --dotfiles-links: string = ""
  --no-ui
] {
  apply-ui-mode $no_ui
  require-ui-tools
  require-password-hash-tool
  require-file-permission-tools
  require-json-schema-tool

  if $dry_run and $apply {
    error make { msg: "use either --dry-run or --apply, not both" }
  }

  mut initial = (default-state)

  if $profile != "" {
    validate-profile $profile
    $initial = ($initial | upsert profile $profile)
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

  if $dotfiles != "" {
    $initial = ($initial | upsert dotfiles $dotfiles)
  }

  if $dotfiles_module != "" {
    $initial = ($initial | upsert dotfiles_module $dotfiles_module)
  }

  if $dotfiles_root != "" {
    $initial = ($initial | upsert dotfiles_root $dotfiles_root)
  }

  if $dotfiles_links != "" {
    let links = parse-dotfiles-links $dotfiles_links
    for link in $links {
      validate-dotfiles-link $link
    }
    $initial = ($initial | upsert dotfiles_links $dotfiles_links)
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

  write-platform-state $final
  write-env $final

  if $final.action == "dry-run" {
    ensure-private-runtime-dir $final.session | ignore
    write-disko-state $final
  }

  print-summary $final

  if $final.action == "apply" {
    run-apply $final
  } else {
    print-next-commands $final
  }
}
