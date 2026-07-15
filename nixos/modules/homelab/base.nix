{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf cfg.enable {
    fileSystems = {
      "/" = lib.mkForce {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
        options = [ "noatime" ];
      };
    };

    systemd.tmpfiles.rules = [
      "d /persist/etc/ssh 0700 root root -"
      "d /persist/var/lib/systemd 0755 root root -"
    ];

    services.openssh = {
      hostKeys = [
        {
          path = "/persist/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    networking.firewall = {
      extraInputRules = ''
        iifname "${cfg.lanInterface}" tcp dport 22 ct state new limit rate 10/minute accept
        iifname "${cfg.lanInterface}" tcp dport 22 drop
        ${lib.optionalString cfg.services.forgejo ''
          iifname "${cfg.lanInterface}" tcp dport 2222 ct state new limit rate 10/minute accept
          iifname "${cfg.lanInterface}" tcp dport 2222 drop
        ''}
      '';
    };
    platform.state.forceShell = pkgs.bashInteractive;
    users = {
      mutableUsers = false;
      defaultUserShell = lib.mkForce pkgs.bashInteractive;
      users.root.hashedPassword = lib.mkForce "!";
    };

    environment.systemPackages = with pkgs; [
      btop
      dnsutils
      git
      iproute2
      speedtest-go
      superfile
      vim
      yazi
    ];

    system.nixos.tags = [ "homelab-${cfg.configVersion}" ];
    environment.variables.HOMELAB_CONFIG_VERSION = cfg.configVersion;
    environment.etc."homelab-version".text = ''
      ${cfg.configVersion}
    '';
    system.stateVersion = lib.mkForce "25.11";
  };
}
