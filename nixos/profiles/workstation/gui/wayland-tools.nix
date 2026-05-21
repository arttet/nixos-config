{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wl-clipboard
    cliphist
    mako
    networkmanagerapplet
    brightnessctl
    pavucontrol
    playerctl
    pamixer
    wiremix
    walker
    wlogout
    blueman
    hyprshot
    wlsunset
  ];
}
