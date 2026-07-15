homelab_script := justfile_directory() / "scripts/homelab.nu"
state_file := env("NIX_CONFIG_LOCAL_STATE", "")
target := env("NIXOS_HOST", "")
target_host := env("NIXOS_TARGET_HOST", "")
nix_build_flags := env("NIX_BUILD_FLAGS", "--option max-jobs auto --option cores 0")

[doc('Validate homelab state and policy without building the image')]
[no-cd]
check:
    NIX_CONFIG_LOCAL_STATE="{{ state_file }}" nix eval --impure ".#nixosConfigurations.{{ target }}.config.system.build.sdImage.drvPath"
    NIX_CONFIG_LOCAL_STATE="{{ state_file }}" nix eval --impure ".#checks.aarch64-linux.homelab-rpi5-policy.drvPath"

[doc('Build the Raspberry Pi 5 microSD image')]
[no-cd]
image:
    mkdir -p target
    NIX_CONFIG_LOCAL_STATE="{{ state_file }}" nix build {{ nix_build_flags }} --impure ".#nixosConfigurations.{{ target }}.config.system.build.sdImage" --out-link target/homelab-rpi5-image
    find target/homelab-rpi5-image/sd-image -maxdepth 1 -name '*.img.zst' -print

[doc('Flash the built image to a whole microSD block device')]
[no-cd]
flash device:
    nu {{ homelab_script }} flash {{ device }}

[doc('Deploy and activate a generation; mode defaults to test')]
[no-cd]
test:
    nixos-rebuild test --impure --sudo --flake ".#{{ target }}" --target-host "{{ target_host }}" {{ nix_build_flags }}

[doc('Switch and activate a generation; mode defaults to test')]
[no-cd]
switch:
    nixos-rebuild switch --impure --sudo --flake ".#{{ target }}" --target-host "{{ target_host }}" {{ nix_build_flags }}

[doc('Set a generation as the boot default without activating it live')]
[no-cd]
boot:
    nixos-rebuild boot --impure --sudo --flake ".#{{ target }}" --target-host "{{ target_host }}" {{ nix_build_flags }}
