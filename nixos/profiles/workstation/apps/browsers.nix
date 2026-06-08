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

  # Privacy preferences: ECH, QUIC, DoH
  zenPrivacyPreferences = {
    # ECH (Encrypted Client Hello)
    "network.dns.echconfig.enabled" = true;
    "network.dns.http3_echconfig.enabled" = true;
    "network.dns.force_waiting_https_rr" = true;
    "security.tls.ech.grease_probability" = 100;
    "security.tls.ech.grease_http3" = true;
    "network.dns.echconfig.fallback_to_origin_when_all_failed" = false;
    # QUIC / HTTP/3
    "network.http.http3.enable" = true;
    # DNS-over-HTTPS
    "network.trr.mode" = 2; # DoH with fallback
    "network.trr.uri" = "https://1.1.1.1/dns-query";
    "network.trr.default_provider_uri" = "https://1.1.1.1/dns-query";
  };

  mkZenPref =
    _name: value:
    if builtins.isBool value then
      if value then "true" else "false"
    else if builtins.isInt value then
      builtins.toString value
    else
      ''"${value}"'';

  zenWithPrivacy =
    (pkgs.wrapFirefox zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default.unwrapped {
      pname = "zen-browser";
      extraPolicies = {
        EncryptedClientHello = {
          Enabled = true;
        };
        DNSOverHTTPS = {
          Enabled = true;
          ProviderURL = "https://1.1.1.1/dns-query";
          Locked = false;
        };
        Preferences = {
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
      };
      extraPrefs = ''
        defaultPref("apz.gtk.pangesture.enabled", true);
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: value: ''
            defaultPref("${name}", ${mkZenPref name value});
          '') zenPrivacyPreferences
        )}
      '';
    }).overrideAttrs
      (old: {
        passthru = (old.passthru or { }) // {
          inherit zenTouchpadPreferences zenPrivacyPreferences;
        };
      });

  # Chrome / Chromium / Brave privacy flags
  chromePrivacyFlags = [
    "--enable-features=EncryptedClientHello"
    "--enable-quic"
    "--force-dark-mode"
    # Security hardening
    "--no-default-browser-check"
    "--disable-background-networking"
    "--disable-component-update"
  ];

  google-chrome-privacy = pkgs.google-chrome.override {
    commandLineArgs = lib.concatStringsSep " " chromePrivacyFlags;
  };

  brave-privacy = pkgs.brave.override {
    commandLineArgs = lib.concatStringsSep " " chromePrivacyFlags;
  };
in
{
  boot.kernel.sysctl."user.max_user_namespaces" = 15000;

  xdg.mime.defaultApplications = {
    "text/html" = lib.mkDefault "zen.desktop";
    "x-scheme-handler/http" = lib.mkDefault "zen.desktop";
    "x-scheme-handler/https" = lib.mkDefault "zen.desktop";
  };

  environment.systemPackages = [
    zenWithPrivacy
    brave-privacy
    google-chrome-privacy
    pkgs.tor-browser
  ];
}
