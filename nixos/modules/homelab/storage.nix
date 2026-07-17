{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.homelab;
  mapperDevice = "/dev/mapper/${cfg.storage.mapperName}";
  unlockStorage = pkgs.writeTextFile {
    name = "homelab-storage-unlock";
    destination = "/bin/homelab-storage-unlock";
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      set -eu

      luks_device="${cfg.storage.luksDevice}"
      mapper_name="${cfg.storage.mapperName}"
      mapper_device="${mapperDevice}"
      expected_fs="${cfg.storage.fileSystemType}"

      if [ ! -e "$luks_device" ]; then
        printf 'Configured LUKS device is absent: %s\n' "$luks_device" >&2
        exit 1
      fi
      if [ ! -e "$mapper_device" ]; then
        ${pkgs.cryptsetup}/bin/cryptsetup open "$luks_device" "$mapper_name"
      fi
      actual_fs="$(${pkgs.util-linux}/bin/lsblk --noheadings --output FSTYPE "$mapper_device" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      if [ "$actual_fs" != "$expected_fs" ]; then
        printf 'Expected filesystem %s on %s, found %s\n' "$expected_fs" "$mapper_device" "$actual_fs" >&2
        exit 1
      fi

      mkdir -p /srv
      if ! ${pkgs.util-linux}/bin/findmnt --mountpoint /srv >/dev/null 2>&1; then
        ${pkgs.util-linux}/bin/mount --types "$expected_fs" "$mapper_device" /srv
      else
        mounted_source="$(${pkgs.util-linux}/bin/findmnt --noheadings --output SOURCE /srv | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        if [ "$mounted_source" != "$mapper_device" ]; then
          printf 'Refusing to reuse /srv mounted from unexpected source: %s\n' "$mounted_source" >&2
          exit 1
        fi
      fi

      mkdir -p /srv/system/log/journal /var/log/journal
      if ! ${pkgs.util-linux}/bin/findmnt --mountpoint /var/log/journal >/dev/null 2>&1; then
        ${pkgs.util-linux}/bin/mount --bind /srv/system/log/journal /var/log/journal
        ${pkgs.systemd}/bin/systemd-tmpfiles --create --prefix /var/log/journal
        ${pkgs.systemd}/bin/systemctl restart systemd-journald
      fi

      mkdir -p /srv/data/forgejo /srv/data/forgejo-runner /srv/data/beszel /srv/data/beszel/agent /srv/data/vikunja /srv/data/vikunja/files /srv/data/gatus /srv/secrets
      ${pkgs.coreutils}/bin/chmod 0755 /srv/data
      ${pkgs.coreutils}/bin/chmod 0750 /srv/data/forgejo /srv/data/forgejo-runner /srv/data/beszel /srv/data/vikunja /srv/data/gatus
      ${pkgs.coreutils}/bin/chmod 0700 /srv/secrets
      ${pkgs.coreutils}/bin/chown root:root /srv/secrets
      ${lib.optionalString cfg.services.podman ''
        mkdir -p /srv/containers/storage
        ${pkgs.coreutils}/bin/chmod 0711 /srv/containers/storage
        ${pkgs.coreutils}/bin/chown root:root /srv/containers/storage
      ''}
      ${lib.optionalString (cfg.services.forgejo || cfg.services.forgejoRunner) ''
        if [ "$(${pkgs.coreutils}/bin/stat -c '%u' /srv/data/forgejo)" != "1000" ]; then
          ${pkgs.coreutils}/bin/chown --recursive 1000:1000 /srv/data/forgejo /srv/data/forgejo-runner
        fi
      ''}
      ${lib.optionalString cfg.services.beszel ''
        if [ "$(${pkgs.coreutils}/bin/stat -c '%U' /srv/data/beszel)" != "beszel" ]; then
          ${pkgs.coreutils}/bin/chown --recursive beszel:beszel /srv/data/beszel
        fi
      ''}
      ${lib.optionalString cfg.services.vikunja ''
        if [ "$(${pkgs.coreutils}/bin/stat -c '%U' /srv/data/vikunja)" != "vikunja" ]; then
          ${pkgs.coreutils}/bin/chown --recursive vikunja:vikunja /srv/data/vikunja
        fi
      ''}
      ${lib.optionalString cfg.services.gatus ''
        if [ "$(${pkgs.coreutils}/bin/stat -c '%U' /srv/data/gatus)" != "gatus" ]; then
          ${pkgs.coreutils}/bin/chown --recursive gatus:gatus /srv/data/gatus
        fi
      ''}
      ${lib.optionalString cfg.services.samba ''
        mkdir -p /srv/samba/state/private
        ${pkgs.coreutils}/bin/chmod 700 /srv/samba/state /srv/samba/state/private
        ${pkgs.coreutils}/bin/chown root:root /srv/samba/state /srv/samba/state/private
        mkdir -p /srv/samba/shared
        ${pkgs.coreutils}/bin/chmod 0750 /srv/samba/shared
        ${pkgs.coreutils}/bin/chown root:samba /srv/samba/shared
        ${lib.concatStrings (
          lib.mapAttrsToList (_name: path: ''
            mkdir -p ${path}
            ${pkgs.coreutils}/bin/chmod 2770 ${path}
            ${pkgs.coreutils}/bin/chown samba:samba ${path}
          '') cfg.samba.shares
        )}
      ''}

      ${pkgs.systemd}/bin/journalctl --flush
      ${pkgs.systemd}/bin/systemctl start homelab-storage.target
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ unlockStorage ];

    systemd.targets.homelab-storage.description = "Homelab services backed by unlocked encrypted /srv storage";

    services.journald.extraConfig = ''
      Storage=auto
      RuntimeMaxUse=256M
      SystemMaxUse=2G
      MaxRetentionSec=14day
    '';
  };
}
