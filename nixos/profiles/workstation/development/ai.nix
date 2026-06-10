{ unstablePkgs, ... }:
{
  environment.systemPackages = [
    unstablePkgs.claude-code
    unstablePkgs.codex
    unstablePkgs.gemini-cli
    unstablePkgs.opencode
  ];
}
