{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wl-clipboard
    cliphist
    grim
    slurp
    mako
    networkmanagerapplet
    brightnessctl
    playerctl
    pamixer
  ];
}
