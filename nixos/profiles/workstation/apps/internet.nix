{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.transmission_4-gtk
    pkgs.yandex-disk
  ];

  # Installs cloudflare-warp and runs the warp-svc daemon warp-cli talks to.
  # One-time manual step after first switch (interactive, can't be
  # expressed in Nix): `warp-cli registration new && warp-cli connect`
  services.cloudflare-warp.enable = true;
}
