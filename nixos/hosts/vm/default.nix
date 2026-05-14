{ ... }:
{
  imports = [
    ../../profiles/vm.nix
  ];

  networking.hostName = "nixos";

  fileSystems."/" = {
    device = "tmpfs";
    fsType = "tmpfs";
  };

  boot.loader.grub.devices = [ "nodev" ];

  users.users.user = {
    isNormalUser = true;
    home = "/home/user";
    extraGroups = [ "wheel" ];
    initialPassword = "user";
  };

  virtualisation.vmVariant = {
    virtualisation = {
      diskSize = 4096;
      memorySize = 1024;
      forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
      ];
      qemu.options = [
        "-nographic"
        "-serial"
        "mon:stdio"
      ];
    };
  };

  environment.etc."motd".text = ''
    NixOS Platform VM

    This disposable VM uses the public user "user" with password "user".
    Real users must be provided through a local overlay outside git.
  '';
}
