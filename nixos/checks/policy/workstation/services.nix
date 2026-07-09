{ workstation, ... }:
[
  {
    assertion = !workstation.services.xserver.enable;
    message = "workstation must remain headless";
  }
  {
    assertion = !workstation.services.openssh.enable;
    message = "workstation must not enable SSH by default";
  }
  {
    assertion = workstation.networking.firewall.enable;
    message = "workstation must enable firewall";
  }
  {
    assertion = workstation.networking.firewall.allowedTCPPorts == [ ];
    message = "workstation must not open TCP ports by default";
  }
  {
    assertion = workstation.networking.firewall.allowedUDPPorts == [ ];
    message = "workstation must not open UDP ports by default";
  }
  {
    assertion = workstation.users.users.root.hashedPassword == "!";
    message = "workstation root password must be locked";
  }
  {
    assertion = workstation.users.users.void.extraGroups == [ ];
    message = "void placeholder user must not have admin groups";
  }
  {
    assertion = workstation.system.stateVersion == "25.11";
    message = "workstation stateVersion must be 25.11";
  }
]
