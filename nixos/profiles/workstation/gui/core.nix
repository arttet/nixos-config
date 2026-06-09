{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../../modules/core/greetd.nix
    ../../../modules/core/sddm.nix
    ../../../modules/themes/default.nix
  ];

  hardware.graphics.enable = lib.mkDefault true;
  hardware.bluetooth.enable = lib.mkDefault true;

  services.dbus.enable = lib.mkDefault true;
  security.polkit.enable = lib.mkDefault true;
  services.gvfs.enable = lib.mkDefault true;
  services.udisks2.enable = lib.mkDefault true;

  services.avahi = {
    enable = lib.mkDefault true;
    nssmdns4 = lib.mkDefault true;
    openFirewall = lib.mkDefault true;
  };

  services.blueman.enable = lib.mkDefault false;

  services.udev.packages = [ pkgs.swayosd ];

  home-manager.sharedModules = [
    {
      services.swayosd = {
        enable = true;
        topMargin = 0.9;
      };
    }
  ];

  platform.greetd.enable = lib.mkDefault false;
  platform.sddm.enable = lib.mkDefault true;
  platform.bootUx.quiet = lib.mkDefault true;
  platform.theme.enable = lib.mkDefault true;

  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
    wireplumber.enable = lib.mkDefault true;
  };

  programs.thunar = {
    enable = lib.mkDefault true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  xdg.portal = {
    enable = lib.mkDefault true;
    xdgOpenUsePortal = lib.mkDefault true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  xdg.mime = {
    enable = lib.mkDefault true;
    defaultApplications."inode/directory" = lib.mkDefault "thunar.desktop";
  };

  # Libvirt is installed for manual QEMU/KVM use, but its services should not
  # participate in the normal boot path.
  #   doas systemctl start libvirtd
  virtualisation.libvirtd = {
    enable = lib.mkDefault true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };
  systemd.services.libvirtd.wantedBy = lib.mkForce [ ];
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [ ];

  programs.virt-manager.enable = lib.mkDefault true;

  environment.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_DBUS_REMOTE = "1";
    GTK_USE_PORTAL = "1";
  };

  environment.systemPackages = [
    pkgs.adwaita-icon-theme
    pkgs.cifs-utils
    pkgs.libsForQt5.qtwayland
    pkgs.qemu
    pkgs.qt6.qtwayland
    pkgs.udiskie
    pkgs.virt-manager
    pkgs.xdg-user-dirs
  ];
}
