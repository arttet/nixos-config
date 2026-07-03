{
  config,
  lib,
  pkgs,
  ...
}:
let
  desktopUsers = lib.filterAttrs (
    _name: user: (user.isNormalUser or false) && (builtins.elem "wheel" (user.extraGroups or [ ]))
  ) config.users.users;

  veracrypt = pkgs.symlinkJoin {
    name = "veracrypt-desktop-${pkgs.veracrypt.version}";
    paths = [ pkgs.veracrypt ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/veracrypt"
      makeWrapper ${pkgs.veracrypt}/bin/veracrypt "$out/bin/veracrypt" \
        --run 'veracrypt_user="''${USER:-''${LOGNAME:-}}"; if [ -n "$veracrypt_user" ]; then export VERACRYPT_MOUNT_PREFIX="/run/media/$veracrypt_user/veracrypt"; fi'
      cp --remove-destination ${pkgs.veracrypt}/share/applications/veracrypt.desktop "$out/share/applications/veracrypt.desktop"
      substituteInPlace "$out/share/applications/veracrypt.desktop" \
        --replace-fail "Exec=${pkgs.veracrypt}/bin/veracrypt %f" "Exec=$out/bin/veracrypt %f"
    '';
  };
in
{
  services.opensnitch = {
    enable = true;
    settings = {
      DefaultAction = "allow";
      Firewall = "nftables";
      InterceptUnknown = true;
    };
  };

  services.clamav.updater.enable = true;

  # Block newly-plugged USB devices by default; devices present at boot keep
  # working. One-time manual step after first switch (run from a physical
  # console, not SSH): `usbguard generate-policy > /var/lib/usbguard/rules.conf`
  # to allow-list currently-trusted devices, then restart usbguard.
  services.usbguard = {
    enable = true;
    presentDevicePolicy = "allow";
    presentControllerPolicy = "allow";
    implicitPolicyTarget = "block";
    ruleFile = "/var/lib/usbguard/rules.conf";
  };

  # Lynis has no NixOS module; run it as a weekly oneshot audit. Reports land
  # in /var/log/lynis.log and /var/log/lynis-report.dat.
  systemd.services.lynis-audit = {
    description = "Lynis security audit (periodic, on-demand)";
    # Lynis shells out to hundreds of system tools (systemctl, ip, ps, ...);
    # the default restricted unit PATH would make it skip most checks.
    path = [ config.system.path ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.lynis}/bin/lynis audit system --cronjob";
    };
  };
  systemd.timers.lynis-audit = {
    description = "Weekly Lynis security audit";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  # VeraCrypt's Linux elevation flow is tightly coupled to sudo-specific
  # behavior, including `sudo -S` and dummy password probes. doas cannot emulate
  # that protocol correctly, so the GUI workstation keeps real sudo available.
  security.sudo.enable = true;
  security.sudo.execWheelOnly = true;
  security.sudo.configFile = lib.mkForce ''
    # Managed by nixos/profiles/workstation/apps/security.nix.
    # sudo is present only for VeraCrypt's sudo-specific Linux elevation flow.
    Defaults env_keep += "VERACRYPT_MOUNT_PREFIX"

    root ALL=(ALL:ALL) ALL
    %wheel ALL=(root) ${veracrypt}/bin/veracrypt --core-service, ${pkgs.veracrypt}/bin/veracrypt --core-service, ${pkgs.veracrypt}/bin/.veracrypt-wrapped --core-service
  '';

  systemd.tmpfiles.rules = [
    "d /run/media 0755 root root -"
  ]
  ++ lib.mapAttrsToList (
    name: user: "d /run/media/${name} 0700 ${name} ${user.group or "users"} -"
  ) desktopUsers;

  environment.systemPackages = [
    pkgs.gnupg
    pkgs.keepassxc
    pkgs.lynis
    pkgs.mat2
    pkgs.nethogs
    pkgs.opensnitch-ui
    pkgs.proton-pass
    pkgs.yara
    pkgs.yubikey-manager
    veracrypt
  ];
}
