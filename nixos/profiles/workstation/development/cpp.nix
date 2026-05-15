{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    cmake
    ninja
    clang
    llvm
    lldb
    gdb
    pkg-config
  ];
}
