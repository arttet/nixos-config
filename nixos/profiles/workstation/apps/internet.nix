{ lib, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isx86_64;
in
{
  environment.systemPackages = [
    pkgs.transmission_4-gtk
  ]
  # yandex-disk publishes no aarch64-linux build.
  ++ lib.optionals isx86_64 [
    pkgs.yandex-disk
  ];

  # Installs cloudflare-warp and runs the warp-svc daemon warp-cli talks to.
  # One-time manual step after first switch (interactive, can't be
  # expressed in Nix): `warp-cli registration new && warp-cli connect`
  # cloudflare-warp publishes no aarch64-linux build in nixpkgs.
  services.cloudflare-warp.enable = isx86_64;
}
