################################################################################
# Requires just >= 1.56.0+
################################################################################

set dotenv-load
set dotenv-path := ".env"

SUDO := env("SUDO", "doas")
NIX_EXTRA_FLAGS := env("NIX_EXTRA_FLAGS", "")

export NIX_CONFIG := env("NIX_CONFIG", "") + "\n" + "extra-experimental-features = nix-command flakes"
export SYSTEMD_COLORS := env("SYSTEMD_COLORS", "1")

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

[doc('Format source files')]
[group('Development')]
fmt:
    @echo "✨ Formatting code..."
    mise exec -- just --fmt
    mise exec -- dprint fmt
    mise exec -- nix fmt
    @echo "✅ Code formatted!"

[doc('Lint source files')]
[group('Development')]
lint:
    @echo "🔍 Running linters..."
    mise run fmt:all
    mise run lint:all
    @echo "✅ Linting complete!"

[doc('Run CI locally')]
[group('Development')]
ci:
    mise exec -- act --list
    mise exec -- act --bind --artifact-server-path target/act-artifacts \
        -P ubuntu-26.04=catthehacker/ubuntu:act-latest

[doc('Remove local caches artifacts')]
[group('Development')]
clean:
    @echo "🧹 Cleaning local caches artifacts..."
    rm -rf .tools target result .wrangler .lycheecache trivy.json trivy-results.sarif
    @just docs clean
    @echo "✅ Clean!"

# ==============================================================================
# NixOS
# ==============================================================================

[doc('Show flake outputs')]
[group('NixOS')]
show:
    nix flake show

[doc('Update flake inputs')]
[group('NixOS')]
update:
    nix flake update

[doc('Run flake checks')]
[group('NixOS')]
check:
    nix flake check

[doc('Build profile')]
[group('NixOS')]
build profile="default":
    nix build --impure --no-link .#nixosConfigurations.{{ profile }}.config.system.build.toplevel {{ NIX_EXTRA_FLAGS }}

[doc('Preview system activation')]
[group('NixOS')]
dry profile="default":
    {{ SUDO }} nixos-rebuild dry-activate --impure --flake "path:{{ justfile_directory() }}#{{ profile }}" {{ NIX_EXTRA_FLAGS }}

[doc('Test system generation')]
[group('NixOS')]
test profile="default":
    just build {{ profile }}
    nix shell nixpkgs#nushell nixpkgs#openssl nixpkgs#jsonschema-cli -c nu scripts/tests/run.nu
    case "{{ profile }}" in default|desktop) nix build .#checks.x86_64-linux.desktop-policy --no-link ;; workstation) nix build .#checks.x86_64-linux.workstation-policy --no-link ;; vm) nix build .#checks.x86_64-linux.vm-policy --no-link ;; *) echo "No policy check is defined for profile: {{ profile }}"; exit 1 ;; esac

[doc('Switch system generation')]
[group('NixOS')]
switch profile="default":
    {{ SUDO }} nixos-rebuild switch --impure --flake "path:{{ justfile_directory() }}#{{ profile }}" {{ NIX_EXTRA_FLAGS }}

[doc('Install boot generation')]
[group('NixOS')]
boot profile="default":
    {{ SUDO }} nixos-rebuild boot --impure --install-bootloader --flake "path:{{ justfile_directory() }}#{{ profile }}" {{ NIX_EXTRA_FLAGS }}

[doc('Rollback system generation')]
[group('NixOS')]
rollback:
    {{ SUDO }} nixos-rebuild switch --rollback

[doc('Show NixOS version')]
[group('NixOS')]
version:
    nixos-version

[doc('List system generations')]
[group('NixOS')]
list:
    {{ SUDO }} nixos-rebuild list-generations

[doc('Show system closure size')]
[group('NixOS')]
size:
    nix path-info -Sh /run/current-system

[doc('Show system dependency tree')]
[group('NixOS')]
tree:
    nix-store -q --tree /run/current-system

[doc('Explain package dependency')]
[group('NixOS')]
why pkg:
    nix why-depends /run/current-system nixpkgs#{{ pkg }}

[doc('Show failed units and errors')]
[group('NixOS')]
failed:
    systemctl list-units --failed
    journalctl --boot --catalog -p err --output=short-iso

[doc('Show current boot logs')]
[group('NixOS')]
logs:
    journalctl --boot --catalog

[doc('Show kernel boot warnings')]
[group('NixOS')]
warn:
    journalctl --boot --dmesg -p warning

[doc('Delete old generations')]
[group('NixOS')]
gc days="30":
    {{ SUDO }} nix-collect-garbage --delete-older-than {{ days }}d

[doc('Optimise Nix store')]
[group('NixOS')]
optimise:
    {{ SUDO }} nix store optimise

[doc('Repair Nix store')]
[group('NixOS')]
repair:
    {{ SUDO }} nix store verify --all --repair

# ==============================================================================
# VM Runtime
# ==============================================================================

[group('VM Runtime')]
mod vm 'misc/justfiles/vm.just'

# ==============================================================================
# Workstation
# ==============================================================================

[group('Workstation')]
mod workstation 'misc/justfiles/workstation.just'

[group('Desktop')]
mod desktop 'misc/justfiles/desktop.just'

[group('Homelab Raspberry Pi')]
mod homelab 'misc/justfiles/homelab.just'

# ==============================================================================
# Local Overlay
# ==============================================================================

[group('Local Overlay')]
mod overlay 'misc/justfiles/overlay.just'

# ==============================================================================
# Documentation
# ==============================================================================

[group('Documentation')]
mod docs 'misc/justfiles/docs.just'
