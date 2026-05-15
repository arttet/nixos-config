{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.alacritty
    pkgs.ghostty
    pkgs.wezterm
  ];
}
