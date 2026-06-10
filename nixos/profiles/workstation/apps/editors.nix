{ unstablePkgs, ... }:
{
  environment.systemPackages = [
    unstablePkgs.neovim
    unstablePkgs.helix
    unstablePkgs.vscode
    unstablePkgs.zed-editor
  ];
}
