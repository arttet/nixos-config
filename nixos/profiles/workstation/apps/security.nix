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
    paths = [
      pkgs.veracrypt
    ];
    nativeBuildInputs = [
      pkgs.makeWrapper
    ];
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
    pkgs.nethogs
    pkgs.opensnitch-ui
    pkgs.proton-pass
    pkgs.yara
    pkgs.yubikey-manager
    veracrypt
  ];
}
