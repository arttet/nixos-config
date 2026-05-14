{ pkgs, lib, ... }:
{
  imports = [
    ./base.nix
    ../modules/core/tuning.nix
    ../modules/storage/disko.nix
    ../modules/storage/swap.nix
  ];

  platform.tuning.enable = true;

  networking.networkmanager.enable = true;

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

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
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
    curl
    git
    gzip
    htop
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
