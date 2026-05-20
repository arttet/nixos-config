{ build, lib, ... }:
{
  imports = [
    ../modules/core/users.nix
    ../modules/core/local-overlay.nix
  ];

  networking.hostName = lib.mkDefault "nixos";
  time.timeZone = lib.mkDefault "UTC";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.supportedLocales = lib.mkDefault [
    "en_US.UTF-8/UTF-8"
    "ru_RU.UTF-8/UTF-8"
  ];

  networking.firewall.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.overlays = [
    (_final: prev: {
      # Keep third-party packages that still reference pkgs.xorg.lndir working
      # without forcing the deprecated nixpkgs alias during evaluation.
      xorg = prev.xorg // {
        lndir = prev.lndir;
      };
    })
  ];

  users.users.root.hashedPassword = "!";

  system.nixos.tags = [
    build.fullVersion
  ];
  environment.variables.CONFIG_VERSION = build.fullVersion;
  environment.etc."build-info".text = ''
    Version: ${build.fullVersion}
  '';

  system.stateVersion = "25.11";
}
