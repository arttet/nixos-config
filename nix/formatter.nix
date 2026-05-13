{
  pkgs,
  treefmt-nix,
  ...
}:

treefmt-nix.lib.evalModule pkgs {
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;

  settings.global.excludes = [
    ".git/**"
    "docs/**"
    "target/**"
  ];
}
