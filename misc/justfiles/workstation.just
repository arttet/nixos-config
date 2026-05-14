[doc('Build the workstation system closure')]
[no-cd]
build:
    nix build .#nixosConfigurations.workstation.config.system.build.toplevel --no-link

[doc('Validate the workstation profile')]
[no-cd]
test: build
    nix eval .#nixosConfigurations.workstation.config.services.qemuGuest.enable --apply 'enabled: if enabled then throw "workstation must not enable qemuGuest" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernelParams --apply 'params: if builtins.elem "console=ttyS0,115200n8" params then throw "workstation must not include VM serial console settings" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.grub.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable GRUB"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.grub.device --apply 'device: if device == "nodev" then "ok" else throw "workstation GRUB must target UEFI nodev"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.grub.efiSupport --apply 'enabled: if enabled then "ok" else throw "workstation GRUB must enable EFI support"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.grub.useOSProber --apply 'enabled: if enabled then throw "workstation must disable OS prober" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.boot.initrd.systemd.enable --apply 'enabled: if enabled then "ok" else throw "workstation must enable systemd initrd"'
    nix eval .#nixosConfigurations.workstation.config.boot.loader.efi.canTouchEfiVariables --apply 'enabled: if enabled then "ok" else throw "workstation must allow EFI variable updates"'
    nix eval .#nixosConfigurations.workstation.config.services.openssh.enable --apply 'enabled: if enabled then throw "workstation must not enable SSH by default" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.users.users.root.hashedPassword --apply 'password: if password == "!" then "ok" else throw "workstation root password must be locked"'
    nix eval .#nixosConfigurations.workstation.config.system.stateVersion --apply 'version: if version == "25.11" then "ok" else throw "workstation stateVersion must be 25.11"'
    nix eval .#nixosConfigurations.workstation.config.hardware.enableRedistributableFirmware --apply 'enabled: if enabled then "ok" else throw "workstation must enable redistributable firmware"'
    nix eval .#nixosConfigurations.workstation.config.nix.gc.automatic --apply 'enabled: if enabled then "ok" else throw "workstation must enable automatic nix gc"'
    nix eval .#nixosConfigurations.workstation.config.nix.settings.auto-optimise-store --apply 'enabled: if enabled then "ok" else throw "workstation must enable store optimisation"'
    nix eval .#nixosConfigurations.workstation.config.platform.storage.enable --apply 'enabled: if enabled then throw "workstation storage layout must stay opt-in" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.platform.storage.swapFilePath --apply 'path: if path == "/swap/swapfile" then "ok" else throw "unexpected workstation swapfile path"'
    nix eval .#nixosConfigurations.workstation.config.platform.storage.swapSizeMiB --apply 'size: if size == 8192 then "ok" else throw "unexpected workstation swapfile size"'
    nix build .#checks.x86_64-linux.workstation-storage-layout
    @echo "Workstation evaluation, closure build, boot model, storage options, and VM-only separation passed."
