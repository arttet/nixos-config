{
  workstation,
  vm,
  pkgs,
  ...
}:
[
  {
    assertion = builtins.elem "--disable-shim-lock" workstation.boot.loader.grub.extraGrubInstallArgs;
    message = "workstation GRUB install args must disable shim lock";
  }
  {
    assertion = builtins.elem "--modules=tpm" workstation.boot.loader.grub.extraGrubInstallArgs;
    message = "workstation GRUB install args must include the tpm module";
  }
  {
    assertion = builtins.elem pkgs.sbctl workstation.environment.systemPackages;
    message = "workstation must install sbctl for Secure Boot key management";
  }
  {
    assertion = builtins.elem pkgs.efibootmgr workstation.environment.systemPackages;
    message = "workstation must install efibootmgr";
  }
  {
    assertion = builtins.elem pkgs.sbsigntool workstation.environment.systemPackages;
    message = "workstation must install sbsigntool";
  }
  {
    assertion = builtins.elem pkgs.grub2 workstation.environment.systemPackages;
    message = "workstation must install grub2";
  }
  {
    assertion = !(builtins.elem pkgs.sbctl vm.environment.systemPackages);
    message = "vm must not install sbctl";
  }
  {
    assertion = !(builtins.elem pkgs.efibootmgr vm.environment.systemPackages);
    message = "vm must not install efibootmgr";
  }
  {
    assertion = !(builtins.elem pkgs.sbsigntool vm.environment.systemPackages);
    message = "vm must not install sbsigntool";
  }
]
