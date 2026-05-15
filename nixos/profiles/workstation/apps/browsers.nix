{
  pkgs,
  lib,
  zen-browser,
  ...
}:
{
  boot.kernel.sysctl."user.max_user_namespaces" = 15000;

  xdg.mime.defaultApplications = {
    "text/html" = lib.mkDefault "zen.desktop";
    "x-scheme-handler/http" = lib.mkDefault "zen.desktop";
    "x-scheme-handler/https" = lib.mkDefault "zen.desktop";
  };

  environment.systemPackages = [
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.brave
    pkgs.google-chrome
    pkgs.tor-browser
  ];
}
