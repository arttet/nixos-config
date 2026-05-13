# modules/core/agent-user.nix
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.mySystem.agentUser = {
    name = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Real user name (defined in overlay)";
    };
    shell = lib.mkOption {
      type = lib.types.package;
      default = pkgs.bash;
    };
    sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config =
    let
      cfg = config.mySystem.agentUser;
    in
    lib.mkMerge [
      {
        # Ensure the option always has a value even if overlay is missing
        mySystem.agentUser.name = lib.mkDefault null;
      }
      (lib.mkIf (cfg.name != null && cfg.name != "") {
        users.users.${cfg.name} = {
          isNormalUser = true;
          inherit (cfg) shell;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = cfg.sshKeys;
        };
      })
    ];
}
