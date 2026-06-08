{ pkgs, ... }:
let
  zoomWithXcbUtil = pkgs.zoom-us.override {
    targetPkgs = fhsPkgs: [
      fhsPkgs.libxcb-util
    ];
  };
in
{
  environment.systemPackages = [
    pkgs.protonmail-desktop
    pkgs.telegram-desktop
    pkgs.thunderbird
    zoomWithXcbUtil
  ];
}
