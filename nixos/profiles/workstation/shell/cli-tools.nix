{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fzf
    ripgrep
    fd
    age
    bandwhich
    bat
    chafa
    delta
    dust
    duf
    eza
    gh
    gping
    hyperfine
    lnav
    micro
    procs
    vendir
    zoxide
  ];
}
