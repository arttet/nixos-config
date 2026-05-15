{ pkgs, lib, ... }:
{
  imports = [
    ../base.nix
    ../../modules/core/network.nix
    ../../modules/core/security.nix
    ../../modules/core/tuning.nix
    ../../modules/storage/disko.nix
    ../../modules/storage/swap.nix
  ];

  platform.network.enable = true;
  platform.security.enable = true;
  platform.tuning.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.systemd.enable = true;

  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = false;
    };
    efi.canTouchEfiVariables = true;
  };

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;

  services.timesyncd.enable = lib.mkDefault true;
  system.autoUpgrade.enable = lib.mkDefault false;
  console.keyMap = lib.mkDefault "us";

  nix = {
    gc = {
      automatic = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
      options = lib.mkDefault "--delete-older-than 14d";
    };
    settings = {
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };

  services.openssh = {
    enable = lib.mkDefault false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = lib.mkDefault false;
    };
  };

  environment.systemPackages = with pkgs; [
    bzip2
    btop
    curl
    git
    gzip
    helix
    jq
    just
    nushell
    pciutils
    unzip
    usbutils
    vim
    wget
    xz
    zip
  ];

  services.xserver.enable = lib.mkForce false;
}
