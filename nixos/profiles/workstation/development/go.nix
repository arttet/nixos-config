{ unstablePkgs, ... }:
{
  environment.systemPackages = [
    unstablePkgs.go
    unstablePkgs.gopls
    unstablePkgs.delve
    unstablePkgs.golangci-lint
  ];
}
