{ pkgs, lib, ... }:
{
  fonts = {
    packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.iosevka-term
    ];

    fontconfig.defaultFonts = {
      monospace = lib.mkDefault [ "IosevkaTerm Nerd Font" ];
      sansSerif = lib.mkDefault [
        "Inter"
        "Noto Sans"
      ];
      serif = lib.mkDefault [ "Noto Serif" ];
      emoji = lib.mkDefault [ "Noto Color Emoji" ];
    };
  };
}
