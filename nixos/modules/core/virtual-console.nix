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
  options.platform.virtualConsole.enable = lib.mkEnableOption "kmscon virtual console with Nerd Font support on tty1";

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

    # The upstream kmscon module does not pull in tty1 when a display manager
    # is enabled. Use its normal target integration without shadowing the
    # packaged kmsconvt@.service template.
    systemd.targets.getty.wants = [ "kmsconvt@tty1.service" ];

    # The generic display-manager unit normally stops autovt@tty1. With kmscon
    # that alias resolves to kmsconvt@tty1, which must remain available.
    systemd.services.display-manager = lib.mkIf config.services.displayManager.enable {
      after = [ "kmsconvt@tty1.service" ];
      conflicts = lib.mkForce [ ];
    };
  };
}
