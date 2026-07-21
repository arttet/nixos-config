{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.virtualConsole;
in
{
  options.platform.virtualConsole.enable = lib.mkEnableOption "kmscon virtual console with Nerd Font support on tty3";

  config = lib.mkIf cfg.enable {
    services.kmscon = {
      enable = true;
      hwRender = true;
      fonts = [
        {
          name = "IosevkaTerm Nerd Font";
          package = pkgs.nerd-fonts.iosevka-term;
        }
      ];
      useXkbConfig = true;
      term = "xterm-256color";
      extraConfig = "font-size=16";
    };

    # SDDM owns tty1, so keep the Nerd Font console on an independent VT.
    systemd.targets.getty.wants = [ "kmsconvt@tty3.service" ];
  };
}
