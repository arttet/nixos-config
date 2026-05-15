{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    python3
    uv
    ruff
    pyright
  ];
}
