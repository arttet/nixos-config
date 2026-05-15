{ pkgs, lib, ... }:
{
  xdg.mime.defaultApplications."application/pdf" = lib.mkDefault "org.pwmt.zathura.desktop";

  environment.systemPackages = with pkgs; [
    obsidian
    libreoffice
    zathura
  ];
}
