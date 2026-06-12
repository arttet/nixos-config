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
    let
      name = lib.getName pkg;
      licenses = lib.toList (pkg.meta.license or [ ]);
      hasCudaLicense = builtins.any (
        license: license == lib.licenses.nvidiaCuda || license == lib.licenses.nvidiaCudaRedist
      ) licenses;
    in
    hasCudaLicense
    || builtins.elem name [
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
