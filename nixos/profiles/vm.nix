{ lib, ... }:
{
  imports = [
    ./workstation.nix
  ];

  services.qemuGuest.enable = true;

  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
  ];

  systemd.services."serial-getty@ttyS0".enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = lib.mkForce true;
    };
  };

  services.xserver.enable = lib.mkForce false;
}
