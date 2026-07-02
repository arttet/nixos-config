{ unstablePkgs, ... }:
{
  environment.systemPackages = [
    unstablePkgs.nodejs
    unstablePkgs.bun
    unstablePkgs.pnpm
    unstablePkgs.typescript
  ];
}
