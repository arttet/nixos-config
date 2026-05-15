{ lib, ... }:
{
  imports = [
    ./base.nix
    ./shell
    ./gui
    ./apps
    ./development
  ];

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "brave"
      "cloudflare-warp"
      "google-chrome"
      "obsidian"
      "protonmail-desktop"
      "proton-pass"
      "veracrypt"
      "vscode"
      "yandex-disk"
      "zoom"
      "zoom-us"
    ];
}
