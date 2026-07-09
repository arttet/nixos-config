{ lib, pkgs, ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  programs.bash.interactiveShellInit = ''
    if [[ -n "''${XDG_RUNTIME_DIR:-}" ]]; then
      HISTFILE="$XDG_RUNTIME_DIR/bash_history"
    fi
  '';

  networking.firewall = {
    enable = true;
    allowedTCPPorts = lib.mkDefault [ ];
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
    doas = {
      enable = true;
      extraRules = [
        {
          groups = [ "wheel" ];
          noPass = true;
          persist = false;
          keepEnv = false;
        }
      ];
    };
  };

  users.defaultUserShell = lib.mkDefault pkgs.bashInteractive;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = lib.mkForce [
      "root"
      "@wheel"
    ];
  };

  environment.systemPackages = with pkgs; [
    bashInteractive
    curl
    tmux
    usbutils
  ];

  boot.supportedFilesystems = lib.mkForce [
    "ext4"
    "vfat"
  ];
  boot.zfs.forceImportRoot = false;

  services.timesyncd.enable = true;
  services.xserver.enable = false;
}
