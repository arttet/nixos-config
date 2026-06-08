{
  pkgs,
  unstablePkgs,
  ...
}:
{
  environment.systemPackages = [
    unstablePkgs.claude-code
    unstablePkgs.codex
    unstablePkgs.gemini-cli
    unstablePkgs.opencode
  ];

  systemd.user.services.kimi-cli-install = {
    description = "Install kimi-cli via uv tool";
    wantedBy = [ "default.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "!%h/.local/share/uv/tools/kimi-cli";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.uv}/bin/uv tool install --python ${pkgs.python313}/bin/python3 kimi-cli";
    };
  };
}
