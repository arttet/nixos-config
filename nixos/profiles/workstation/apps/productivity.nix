{ pkgs, lib, ... }:
{
  xdg.mime.defaultApplications."application/pdf" = lib.mkDefault "org.pwmt.zathura.desktop";

  environment.systemPackages =
    with pkgs;
    [
      mission-center
      obsidian
      sqlitebrowser
      typst
      zathura
    ]
    # onlyoffice-desktopeditors publishes no aarch64-linux build.
    ++ lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      pkgs.onlyoffice-desktopeditors
    ];
}
