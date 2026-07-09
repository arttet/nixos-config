{ build, ... }:
{
  imports = [
    ./server.nix
    ../modules/core/local.nix
    ../modules/core/state.nix
    ../modules/homelab/server.nix
  ];

  platform.homelab = {
    enable = true;
    configVersion = build.homelabFullVersion;
    services = {
      samba = true;
    };
  };

  # Trust the CI-built binary cache so `nixos-rebuild switch` on real
  # Raspberry Pi 5 hardware can pull pre-built substitutes instead of
  # building the full aarch64-linux closure locally.
  nix.settings = {
    substituters = [ "https://homelab-rpi5.cachix.org" ];
    trusted-public-keys = [
      "homelab-rpi5.cachix.org-1:qGR3IBfqYtjY0VjQgEAHDaABJlwzMyGCTPnRl7mdiY8="
    ];
  };
}
