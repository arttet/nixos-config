{ pkgs, lib, ... }:
{
  fonts = {
    packages = with pkgs; [
      # Primary UI font.
      inter

      # Reading and editor alternatives.
      lexend

      # Broad language and emoji coverage.
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji

      # Terminal and code fonts.
      nerd-fonts.caskaydia-cove
      nerd-fonts.iosevka-term
    ];

    fontconfig = {
      defaultFonts = {
        serif = lib.mkDefault [ "Noto Serif" ];
        sansSerif = lib.mkDefault [
          "Inter"
          "Noto Sans"
        ];
        monospace = lib.mkDefault [
          "IosevkaTerm Nerd Font"
        ];
        emoji = lib.mkDefault [ "Noto Color Emoji" ];
      };

      hinting = {
        enable = lib.mkDefault true;
        style = lib.mkDefault "slight";
        autohint = lib.mkDefault false;
      };

      subpixel = {
        rgba = lib.mkDefault "vrgb";
        lcdfilter = lib.mkDefault "default";
      };

      antialias = lib.mkDefault true;
    };
  };
}
