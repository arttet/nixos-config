{ lib, ... }:
{
  imports = [
    ./workstation.nix
  ];

  platform.tuning.enable = lib.mkForce false;

  services.qemuGuest.enable = true;

  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
  ];

  systemd.services."serial-getty@ttyS0".enable = true;

  virtualisation.vmVariant.virtualisation.graphics = lib.mkForce false;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = lib.mkForce true;
    };
  };

  services.xserver.enable = lib.mkForce false;
}
