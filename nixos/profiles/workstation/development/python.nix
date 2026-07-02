{ unstablePkgs, ... }:
{
  environment.systemPackages = [
    unstablePkgs.python3
    unstablePkgs.uv
    unstablePkgs.ruff
    unstablePkgs.pyright
  ];
}
