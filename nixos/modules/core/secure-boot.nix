{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.platform.secureBoot;
  bootMountPoint = "/boot";
  efiMountPoint = config.boot.loader.efi.efiSysMountPoint;
  secureBootTools = with pkgs; [
    sbctl
    efibootmgr
    sbsigntool
    grub2
  ];
in
{
  options.platform.secureBoot = {
    enable = lib.mkEnableOption "Secure Boot support for GRUB-based workstation systems";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = secureBootTools;

    boot.loader.grub = {
      extraInstallCommands = lib.mkAfter ''
        boot_mount="${bootMountPoint}"
        find_bin="${pkgs.findutils}/bin/find"
        sbctl_bin="${pkgs.sbctl}/bin/sbctl"
        efi_mount="${efiMountPoint}"

        if [ ! -d "$boot_mount" ]; then
          echo "secure-boot: boot mount point $boot_mount does not exist" >&2
          exit 1
        fi

        if [ ! -d "$efi_mount" ]; then
          echo "secure-boot: ESP mount point $efi_mount does not exist" >&2
          exit 1
        fi

        if [ -z "$("$find_bin" /var/lib/sbctl/keys -type f -name '*.key' -print -quit 2>/dev/null)" ]; then
          echo "secure-boot: sbctl keys not found; skipping EFI signing (run 'sbctl create-keys' and 'sbctl enroll-keys -m' after first boot, then rebuild)" >&2
        else
          echo "secure-boot: signing EFI artifacts under $efi_mount"
          "$find_bin" "$efi_mount" -type f -iname '*.efi' -exec "$sbctl_bin" sign -s '{}' ';'

          echo "secure-boot: discovering kernel images under $boot_mount"
          kernels="$("$find_bin" "$boot_mount" -type f \( -iname '*bzImage*' -o -iname '*vmlinuz*' -o -iname '*zImage*' -o -iname '*-Image*' \) -print)"

          if [ -z "$kernels" ]; then
            echo "secure-boot: no kernel images found under $boot_mount — check filename patterns" >&2
            "$find_bin" "$boot_mount" -maxdepth 3 -type f -printf '  %p\n' >&2
            exit 1
          fi

          echo "secure-boot: signing kernel images:"
          echo "$kernels" | while IFS= read -r kernel; do
            echo "  $kernel"
            "$sbctl_bin" sign -s "$kernel"
          done
        fi
      '';
    };
  };
}
