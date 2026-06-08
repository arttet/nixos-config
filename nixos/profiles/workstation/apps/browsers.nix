{
  pkgs,
  lib,
  zen-browser,
  ...
}:
let
  zenTouchpadPreferences = {
    "apz.gtk.pangesture.enabled" = true;
    "browser.gesture.swipe.left" = "Browser:BackOrBackDuplicate";
    "browser.gesture.swipe.right" = "Browser:ForwardOrForwardDuplicate";
    "browser.history_swipe_animation.disabled" = false;
    "widget.disable-swipe-tracker" = false;
  };

  zenWithTouchpadGestures =
    (pkgs.wrapFirefox zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default.unwrapped {
      pname = "zen-browser";
      extraPolicies.Preferences = {
        "browser.gesture.swipe.left" = {
          Value = zenTouchpadPreferences."browser.gesture.swipe.left";
          Status = "default";
        };
        "browser.gesture.swipe.right" = {
          Value = zenTouchpadPreferences."browser.gesture.swipe.right";
          Status = "default";
        };
        "browser.history_swipe_animation.disabled" = {
          Value = zenTouchpadPreferences."browser.history_swipe_animation.disabled";
          Status = "default";
        };
        "widget.disable-swipe-tracker" = {
          Value = zenTouchpadPreferences."widget.disable-swipe-tracker";
          Status = "locked";
        };
      };
      extraPrefs = ''
        defaultPref("apz.gtk.pangesture.enabled", true);
      '';
    }).overrideAttrs
      (old: {
        passthru = (old.passthru or { }) // {
          inherit zenTouchpadPreferences;
        };
      });
in
{
  boot.kernel.sysctl."user.max_user_namespaces" = 15000;

  xdg.mime.defaultApplications = {
    "text/html" = lib.mkDefault "zen.desktop";
    "x-scheme-handler/http" = lib.mkDefault "zen.desktop";
    "x-scheme-handler/https" = lib.mkDefault "zen.desktop";
  };

  environment.systemPackages = [
    zenWithTouchpadGestures
    pkgs.brave
    pkgs.google-chrome
    pkgs.tor-browser
  ];
}
