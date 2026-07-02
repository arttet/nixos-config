set dotenv-load
set dotenv-path := ".envrc"

# ==============================================================================
# Help
# ==============================================================================

[doc('Show help')]
default: help

[doc('List all commands')]
help:
    @just --list --unsorted --list-submodules

# ==============================================================================
# Development
# ==============================================================================

[doc('Format code')]
[group('Development')]
fmt:
    @echo "✨ Formatting code..."
    dprint fmt
    just --fmt
    nix fmt
    @echo "✅ Code formatted!"

[doc('Run repository checks')]
[group('Development')]
check:
    nix flake check

[doc('Build a NixOS profile closure')]
[group('Development')]
build profile="default":
    nix build --impure .#nixosConfigurations.{{ profile }}.config.system.build.toplevel --no-link

[doc('Run script tests and selected profile checks')]
[group('Development')]
test profile="default":
    just build {{ profile }}
    nix shell nixpkgs#nushell nixpkgs#openssl nixpkgs#check-jsonschema -c nu scripts/tests/run.nu
    case "{{ profile }}" in default|desktop) nix build .#checks.x86_64-linux.desktop-policy --no-link ;; workstation) nix build .#checks.x86_64-linux.workstation-policy --no-link ;; vm) nix build .#checks.x86_64-linux.vm-policy --no-link ;; *) echo "No policy check is defined for profile: {{ profile }}"; exit 1 ;; esac

[doc('Switch the installed NixOS system to a profile')]
[group('Development')]
switch profile="default":
    doas nixos-rebuild switch --install-bootloader --flake "path:{{ justfile_directory() }}#{{ profile }}" --impure

# ==============================================================================
# VM Runtime
# ==============================================================================

[group: 'VM Runtime']
mod vm 'misc/justfiles/vm.just'

# ==============================================================================
# Workstation
# ==============================================================================

[group: 'Workstation']
mod workstation 'misc/justfiles/workstation.just'

[group: 'Desktop']
mod desktop 'misc/justfiles/desktop.just'

# ==============================================================================
# Local Overlay
# ==============================================================================

[group: 'Local Overlay']
mod overlay 'misc/justfiles/overlay.just'

# ==============================================================================
# Documentation
# ==============================================================================

[group: 'Documentation']
mod docs 'misc/justfiles/docs.just'
