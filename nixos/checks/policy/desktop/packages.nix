{
  self,
  unstablePkgs,
  desktop,
  hasAllPackages,
  findPackage,
  packageNames,
  requiredGuiRuntimePackages,
  requiredGuiApplicationPackages,
  requiredGuiFontPackages,
  ...
}:
[
  {
    assertion = hasAllPackages desktop.environment.systemPackages requiredGuiRuntimePackages;
    message = "desktop must include baseline runtime UX tools";
  }
  {
    assertion = hasAllPackages desktop.environment.systemPackages requiredGuiApplicationPackages;
    message = "desktop application and development baseline is incomplete";
  }
  {
    assertion =
      findPackage "nvtop" desktop.environment.systemPackages
      == self.nixosConfigurations.desktop.pkgs.nvtopPackages.full;
    message = "desktop must use full multi-vendor nvtop";
  }
  {
    assertion =
      findPackage "neovim" desktop.environment.systemPackages == unstablePkgs.neovim
      && findPackage "helix" desktop.environment.systemPackages == unstablePkgs.helix
      && findPackage "vscode" desktop.environment.systemPackages == unstablePkgs.vscode
      && findPackage "zed-editor" desktop.environment.systemPackages == unstablePkgs.zed-editor;
    message = "desktop must use editors from nixpkgs-unstable";
  }
  {
    assertion = hasAllPackages desktop.fonts.packages requiredGuiFontPackages;
    message = "desktop font baseline is incomplete";
  }
  {
    assertion =
      let
        names = packageNames desktop.environment.systemPackages;
      in
      !(builtins.elem "waybar" names)
      && !(builtins.elem "eww" names)
      && !(builtins.elem "nautilus" names)
      && !(builtins.elem "dolphin" names)
      && !(builtins.elem "rofi" names);
    message = "desktop must not include Waybar, EWW, Nautilus, Dolphin, or Rofi as baseline";
  }
]
