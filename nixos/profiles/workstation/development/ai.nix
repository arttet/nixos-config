{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.codex
    pkgs.claude-code
    pkgs.opencode
  ];
}
