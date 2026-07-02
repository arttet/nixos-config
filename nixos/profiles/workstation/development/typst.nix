{ unstablePkgs, ... }:
{
  environment.systemPackages = [
    unstablePkgs.typst
    unstablePkgs.typstyle
  ];
}
