{ unstablePkgs, ... }:
{
  environment.systemPackages = [
    unstablePkgs.cmake
    unstablePkgs.ninja
    unstablePkgs.clang
    unstablePkgs.llvm
    unstablePkgs.lldb
    unstablePkgs.gdb
    unstablePkgs.pkg-config
    unstablePkgs.gcc
  ];
}
