{
  config,
  lib,
}:
let
  packageNames = map lib.getName config.environment.systemPackages;
  hasPackage = name: builtins.elem name packageNames;
  hasUnit = name: builtins.hasAttr name config.systemd.services;
  hasContainer = name: builtins.hasAttr name config.virtualisation.oci-containers.containers;

  baseChecks = [
    {
      assertion = config.system.stateVersion == "25.11";
      message = "homelab-rpi5 migration baseline must remain 25.11";
    }
    {
      assertion = config.nixpkgs.hostPlatform.system == "aarch64-linux";
      message = "homelab-rpi5 evaluates as aarch64-linux";
    }
    {
      assertion = config.system.build ? sdImage;
      message = "homelab-rpi5 exposes an SD image build";
    }
    {
      assertion =
        config.fileSystems."/".fsType == "ext4"
        && config.fileSystems."/".device == "/dev/disk/by-label/NIXOS_SD";
      message = "homelab-rpi5 recovery image boots from the SD ext4 root";
    }
    {
      assertion = hasPackage "bash-interactive" || hasPackage "bash";
      message = "homelab-rpi5 includes Bash as the baseline interactive shell";
    }
    {
      assertion = hasPackage "curl" && hasPackage "usbutils" && hasPackage "tmux";
      message = "homelab-rpi5 includes the minimal server diagnostic package baseline";
    }
  ];

  storageChecks = [
    {
      assertion =
        !(builtins.hasAttr "/srv" config.fileSystems)
        && config.boot.initrd.luks.devices == { }
        && config.systemd.targets.homelab-storage.wantedBy == [ ];
      message = "homelab boot does not require encrypted /srv";
    }
    {
      assertion = hasPackage "homelab-storage-unlock";
      message = "homelab-rpi5 installs the storage unlock operator command";
    }
  ];

  accessChecks = [
    {
      assertion =
        !config.services.openssh.settings.PasswordAuthentication
        && !config.services.openssh.settings.KbdInteractiveAuthentication
        && config.services.openssh.settings.PermitRootLogin == "no";
      message = "homelab-rpi5 permits key-only non-root SSH";
    }
    {
      assertion = config.users.users.root.hashedPassword == "!";
      message = "homelab-rpi5 locks the root password";
    }
  ];

  runtimeChecks = [
    {
      assertion = !hasPackage "homelab-status" && !hasUnit "homelab-status";
      message = "homelab-rpi5 does not install the removed homelab-status command";
    }
    {
      assertion =
        config.virtualisation.podman.enable
        && config.virtualisation.podman.dockerCompat
        && config.virtualisation.podman.dockerSocket.enable
        && config.virtualisation.oci-containers.backend == "podman"
        && !config.virtualisation.docker.enable;
      message = "homelab-rpi5 uses Podman as the only container runtime";
    }
    {
      assertion =
        !(hasContainer "k3s")
        && !(hasUnit "k3s")
        && !(hasUnit "containerd")
        && !(builtins.elem 6443 config.networking.firewall.allowedTCPPorts)
        && !(builtins.elem 8472 config.networking.firewall.allowedUDPPorts)
        && !(builtins.elem 10250 config.networking.firewall.allowedTCPPorts);
      message = "homelab-rpi5 has no k3s/containerd runtime or cluster firewall exposure";
    }
    {
      assertion =
        let
          containers = config.virtualisation.oci-containers.containers or { };
          hasHealthCheck =
            container: builtins.any (opt: lib.hasPrefix "--health-cmd" opt) container.extraOptions;
        in
        builtins.all hasHealthCheck (lib.attrValues containers);
      message = "every homelab container must define a podman --health-cmd";
    }
  ];
in
lib.concatLists [
  baseChecks
  storageChecks
  accessChecks
  runtimeChecks
]
