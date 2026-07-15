{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.homelab;
  setPassword = pkgs.writeTextFile {
    name = "homelab-samba-password-set";
    destination = "/bin/homelab-samba-password-set";
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      set -eu

      if ! ${pkgs.util-linux}/bin/findmnt --mountpoint /srv >/dev/null 2>&1; then
        printf 'Encrypted /srv is not mounted. Run homelab-storage-unlock first.\n' >&2
        exit 1
      fi
      exec ${pkgs.samba}/bin/smbpasswd -a samba
    '';
  };
  shareSettings = lib.mapAttrs (_name: path: {
    inherit path;
    browseable = "yes";
    "create mask" = "0660";
    "directory mask" = "2770";
    "force group" = "samba";
    "force user" = "samba";
    "guest ok" = "no";
    "read only" = "no";
    "valid users" = "samba";
  }) cfg.samba.shares;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.samba) {
    environment.systemPackages = [
      pkgs.samba
      setPassword
    ];

    users.groups.samba = { };
    users.users.samba = {
      isSystemUser = true;
      group = "samba";
      home = "/var/empty";
      createHome = false;
    };

    services.samba = {
      enable = true;
      openFirewall = false;
      winbindd.enable = false;
      settings = {
        global = {
          "bind interfaces only" = "yes";
          "disable netbios" = "yes";
          interfaces = "lo ${cfg.lanInterface}";
          "log level" = "1";
          "map to guest" = "never";
          "server max protocol" = "SMB3";
          "server min protocol" = "SMB3_00";
          "smb encrypt" = "required";
          "state directory" = "/srv/samba/state";
          "private dir" = "/srv/samba/state/private";
        };
      }
      // shareSettings;
    };
    systemd.services.samba-smbd = {
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
    };
    systemd.services.samba-nmbd.enable = false;

    networking.firewall.extraInputRules = ''
      ip saddr ${cfg.lanCidr} tcp dport 445 accept
    '';
  };
}
