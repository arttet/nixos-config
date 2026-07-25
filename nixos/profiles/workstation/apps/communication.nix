{ lib, pkgs, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) isx86_64;

  zoomWithXcbUtil = pkgs.zoom-us.override {
    targetPkgs = fhsPkgs: [
      fhsPkgs.libxcb-util
    ];
  };
in
{
  environment.systemPackages = [
    pkgs.telegram-desktop
    pkgs.thunderbird
  ]
  # protonmail-desktop and zoom-us publish no aarch64-linux build.
  ++ lib.optionals isx86_64 [
    pkgs.protonmail-desktop
    zoomWithXcbUtil
  ];
}
