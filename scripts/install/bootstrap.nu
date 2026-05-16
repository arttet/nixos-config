#!/usr/bin/env nu

use common.nu *

def default-state [] {
  {
    install_id: "pc"
    profile: "default"
    user: "user"
    password: ""
    password_hash: ""
    hostname: "pc"
    timezone: "UTC"
    disk: ""
    action: "dry-run"
  }
}

def state-root [] {
  $env.NIX_CONFIG_INSTALL_STATE_DIR? | default (join-path [ $env.HOME ".cache" "nixos-config-installer" "state" ])
}

def install-dir [install_id: string] {
  join-path [ (state-root) $install_id ]
}

def ensure-private-install-dir [install_id: string] {
  let dir = (install-dir $install_id)
  ensure-dir $dir
  chmod 700 $dir
  $dir
}

def overlay-path [install_id: string] {
  join-path [ (install-dir $install_id) "user.nix" ]
}

def password-path [install_id: string] {
  join-path [ (install-dir $install_id) "user.passwd" ]
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

def env-path [install_id: string] {
  join-path [ (install-dir $install_id) "install.env" ]
}

def hardware-config-path [] {
  "/mnt/etc/nixos/hardware-configuration.nix"
}

def disko-config-path [] {
  join-path [ (temp-root) "workstation-disko.nix" ]
}

def flake-uri [profile: string] {
  if $profile == "default" {
    $"path:(repo-root)#"
  } else {
    $"path:(repo-root)#($profile)"
  }
}

def prompt-default [label: string, default: string] {
  let answer = (input $"($label) [($default)]: " | str trim)

  if $answer == "" {
    $default
  } else {
    $answer
  }
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

    print $validation.msg
    print "Try again, enter r to go back, or q to quit."
  }
}

def validate-id [value: string] {
  if not ($value =~ '^[A-Za-z0-9_-]+$') {
    error make { msg: "install id may contain only letters, numbers, underscore, and dash" }
  }
}

def validate-user [value: string] {
  if $value == "root" {
    error make { msg: "username cannot be root" }
  }

  if not ($value =~ '^[a-z_][a-z0-9_-]*$') {
    error make { msg: "username must start with a lowercase letter or underscore and contain only lowercase letters, numbers, underscore, and dash" }
  }
}

def validate-password [value: string] {
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

def validate-hostname [value: string] {
  if not ($value =~ '^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$') {
    error make { msg: "hostname must use RFC 1123 labels: letters, digits, and hyphens only" }
  }
}

def derive-hostname [id: string, current: string] {
  if $id =~ '^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$' {
    $id
  } else {
    $current
  }
}

def validate-timezone [value: string] {
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

def validate-profile [value: string] {
  if not ($value in [ "default" "workstation" "workstation-gui" ]) {
    error make { msg: "profile must be default, workstation, or workstation-gui" }
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
  print ""
  print "Disk discovery:"
  print "  lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL,MOUNTPOINTS"
  print "  ls -l /dev/disk/by-id/"
  print ""

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

      print $validation.msg
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

        print $validation.msg
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
  ensure-private-install-dir $state.install_id | ignore

  let overlay = $"
{ pkgs, lib, ... }:
{
  networking.hostName = lib.mkDefault \"($state.hostname)\";
  time.timeZone = lib.mkDefault \"($state.timezone)\";

  users.users.\"($state.user)\" = {
    isNormalUser = true;
    shell = pkgs.nushell;
    hashedPasswordFile = \"(target-password-path)\";
    extraGroups = [ \"wheel\" ];
  };
}
"

  $overlay | save --force (overlay-path $state.install_id)
}

def write-password-file [state: record] {
  ensure-private-install-dir $state.install_id | ignore

  let path = (password-path $state.install_id)
  install -m 600 /dev/null $path
  $state.password_hash | save --force $path
  chmod 600 $path
}

def write-env [state: record] {
  let env_file = $"
export NIX_CONFIG_LOCAL_USER=\"(overlay-path $state.install_id)\"
export NIX_CONFIG_LOCAL_HARDWARE=\"(hardware-config-path)\"
"

  $env_file | save --force (env-path $state.install_id)
}

def print-summary [state: record] {
  print ""
  print "Install summary"
  print $"  install id:       ($state.install_id)"
  print $"  profile:          ($state.profile)"
  print $"  user:             ($state.user)"
  print $"  hostname:         ($state.hostname)"
  print $"  timezone:         ($state.timezone)"
  print $"  disk:             ($state.disk)"
  print $"  local overlay:    (overlay-path $state.install_id)"
  print $"  password hash:    (password-path $state.install_id)"
  print $"  install env:      (env-path $state.install_id)"
  print $"  hardware config:  (hardware-config-path)"
}

def print-next-commands [state: record] {
  let repo = (repo-root)
  let flake = (flake-uri $state.profile)

  print ""
  print "Generated files:"
  print $"  (overlay-path $state.install_id)"
  print $"  (password-path $state.install_id)"
  print $"  (env-path $state.install_id)"
  print $"  (disko-config-path)"
  print ""
  print "Dry-run complete. No destructive command was run."
  print ""
  print "To apply after review:"
  print $"  source \"(env-path $state.install_id)\""
  print $"  nu \"($repo)/scripts/install/disko.nu\" \"($state.disk)\""
  print "  nixos-generate-config --root /mnt"
  print "  test -f /mnt/etc/nixos/hardware-configuration.nix"
  print $"  NIX_CONFIG_LOCAL_USER=\"(overlay-path $state.install_id)\" \\"
  print $"  NIX_CONFIG_LOCAL_HARDWARE=\"(hardware-config-path)\" \\"
  print $"  nixos-install --impure --flake \"($flake)\""
}

def confirm-disk [disk_device: string] {
  print ""
  print "DESTRUCTIVE WARNING"
  print $"Disk selected for formatting: ($disk_device)"
  print "This will repartition and format the selected disk."
  print ""
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

  print "Applying disk layout..."
  nu $"($repo)/scripts/install/disko.nu" $state.disk --yes --config (disko-config-path)
  if $env.LAST_EXIT_CODE != 0 {
    error make { msg: "disko failed; aborting before hardware generation and nixos-install" }
  }

  print "Generating hardware configuration..."
  nixos-generate-config --root /mnt
  if $env.LAST_EXIT_CODE != 0 {
    error make { msg: "nixos-generate-config failed" }
  }

  if not ((hardware-config-path) | path exists) {
    error make { msg: "hardware configuration was not generated" }
  }

  print "Persisting local overlay to target system..."
  let persistent_user_dir = (target-local-dir)
  mkdir $persistent_user_dir
  chmod 700 $persistent_user_dir
  cp (overlay-path $state.install_id) $"($persistent_user_dir)/user.nix"
  install -m 600 (password-path $state.install_id) (mounted-target-password-path)

  print "Installing NixOS..."
  with-env {
    NIX_CONFIG_LOCAL_USER: $"($persistent_user_dir)/user.nix"
    NIX_CONFIG_LOCAL_HARDWARE: (hardware-config-path)
  } {
    nixos-install --impure --flake $flake --no-root-passwd
    if $env.LAST_EXIT_CODE != 0 {
      error make { msg: "nixos-install failed" }
    }
  }

  print ""
  print "Install command completed. Reboot when ready:"
  print "  reboot"
  print ""
  print "First boot checks:"
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

  loop {
    if $step == 0 {
      let value = (prompt-validated "Install id" $state.install_id {|input| validate-id $input })
      if $value == "q" { exit 0 }
      let next_hostname = (derive-hostname $value $state.hostname)
      $state = ($state | upsert install_id $value | upsert hostname $next_hostname)
      $step = 1
    } else if $step == 1 {
      let value = (prompt-validated "Profile" $state.profile {|input| validate-profile $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 0 } else {
        $state = ($state | upsert profile $value)
        $step = 2
      }
    } else if $step == 2 {
      let value = (prompt-validated "Username" $state.user {|input| validate-user $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 1 } else {
        $state = ($state | upsert user $value)
        $step = 3
      }
    } else if $step == 3 {
      let value = (prompt-validated "User Password (for initial login)" $state.password {|input| validate-password $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 2 } else {
        $state = ($state | upsert password $value)
        $step = 4
      }
    } else if $step == 4 {
      let value = (prompt-validated "Hostname" $state.hostname {|input| validate-hostname $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 3 } else {
        $state = ($state | upsert hostname $value)
        $step = 5
      }
    } else if $step == 5 {
      print "Timezone hint: timedatectl list-timezones"
      let value = (prompt-validated "Timezone" $state.timezone {|input| validate-timezone $input })
      if $value == "q" { exit 0 }
      if $value == "r" { $step = 4 } else {
        $state = ($state | upsert timezone $value)
        $step = 6
      }
    } else if $step == 6 {
      let value = if $state.disk == "" { choose-disk "" } else { choose-disk $state.disk }
      if $value == "r" { $step = 5 } else {
        validate-disk $value
        $state = ($state | upsert disk $value)
        $step = 7
      }
    } else if $step == 7 {
      print-summary $state
      print ""
      print "[d] dry-run"
      print "[a] apply"
      print "[r] back"
      print "[q] quit"
      let value = (input $"Action [($state.action)]: " | str trim)

      if $value == "q" { exit 0 }
      if $value == "r" { $step = 6 } else if $value == "a" or $value == "apply" {
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
  --install-id: string = ""
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

  if $install_id != "" {
    validate-id $install_id
    let next_hostname = (derive-hostname $install_id $initial.hostname)
    $initial = ($initial | upsert install_id $install_id | upsert hostname $next_hostname)
  }

  if $user != "" {
    validate-user $user
    $initial = ($initial | upsert user $user)
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
