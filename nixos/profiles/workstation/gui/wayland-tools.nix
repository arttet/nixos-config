{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wl-clipboard
    cliphist
    mako
    networkmanagerapplet
    blueman
    bluetui
    brightnessctl
    pavucontrol
    playerctl
    pamixer
    wiremix
    wlogout
    hyprshot
    wlsunset
  ];
}
