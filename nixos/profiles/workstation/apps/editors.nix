{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.neovim
    pkgs.helix
    pkgs.vscode
    pkgs.zed-editor
  ];
}
