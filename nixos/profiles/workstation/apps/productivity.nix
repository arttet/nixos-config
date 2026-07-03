{ pkgs, lib, ... }:
{
  xdg.mime.defaultApplications."application/pdf" = lib.mkDefault "org.pwmt.zathura.desktop";

  environment.systemPackages = with pkgs; [
    mission-center
    obsidian
    onlyoffice-desktopeditors
    sqlitebrowser
    typst
    zathura
  ];
}
