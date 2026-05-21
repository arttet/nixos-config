{ pkgs, lib, ... }:
{
  imports = [
    ../base.nix
    ../../modules/core/network.nix
    ../../modules/core/security.nix
    ../../modules/core/secure-boot.nix
    ../../modules/core/tuning.nix
    ../../modules/core/power.nix
    ../../modules/core/boot-ux.nix
    ../../modules/storage/disko.nix
    ../../modules/storage/swap.nix
  ];

  platform.bootUx.enable = true;
  platform.network.enable = true;
  platform.security.enable = true;
  platform.secureBoot.enable = true;
  platform.tuning.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.systemd.enable = true;

  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = false;
      extraGrubInstallArgs = [
        "--disable-shim-lock"
        "--modules=tpm"
      ];
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
  };

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;

  services.timesyncd.enable = lib.mkDefault true;
  system.autoUpgrade.enable = lib.mkDefault false;
  console.keyMap = lib.mkDefault "us";
  services.xserver.xkb = {
    layout = lib.mkDefault "us,ru";
    options = lib.mkDefault "grp:alt_shift_toggle";
  };

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
