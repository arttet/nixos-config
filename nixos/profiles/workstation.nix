{ pkgs, lib, ... }:
{
  imports = [
    ./base.nix
  ];

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = lib.mkDefault false;
    };
  };

  environment.systemPackages = with pkgs; [
    curl
    dnsutils
    git
    htop
    inetutils
    iproute2
    iputils
    jq
    just
    lsof
    ncdu
    nushell
    pciutils
    ripgrep
    smartmontools
    tcpdump
    traceroute
    tree
    usbutils
    vim
    wget
  ];

  services.xserver.enable = lib.mkForce false;
}
