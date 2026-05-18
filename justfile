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

[doc('Prepare this checkout for privileged local rebuilds')]
[group('Development')]
setup:
    doas git config --global --add safe.directory "$(pwd)"

[doc('Format code')]
[group('Development')]
fmt:
    @echo "✨ Formatting code..."
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
    nu scripts/tests/run.nu
    nix eval --impure .#nixosConfigurations.{{ profile }}.config.boot.loader.grub.enable --apply 'enabled: if enabled then "ok" else throw "profile must enable GRUB"'
    nix eval --impure .#nixosConfigurations.{{ profile }}.config.environment.systemPackages --apply 'packages: let has = name: builtins.any (pkg: let pname = pkg.pname or ""; full = pkg.name or ""; in pname == name || full == name || builtins.match "${name}-.*" full != null) packages; required = [ "sbctl" "efibootmgr" "sbsigntool" "grub" ]; missing = builtins.filter (name: !(has name)) required; in if missing == [] then "ok" else throw "profile is missing Secure Boot tooling"'

[doc('Switch the installed NixOS system to a profile')]
[group('Development')]
switch profile="default":
    doas nixos-rebuild switch --install-bootloader --flake .#{{ profile }} --impure

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

[group: 'Workstation GUI']
mod workstation-gui 'misc/justfiles/workstation-gui.just'

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

# ==============================================================================
# Pull Requests
# ==============================================================================

[group: 'Pull Requests']
mod pr 'misc/justfiles/pr.just'

alias prc := pr::create
alias prr := pr::review
alias prv := pr::view

# ==============================================================================
# Deployment
# ==============================================================================

[group: 'Deployment']
mod deploy 'misc/justfiles/deployment.just'

alias dl := deploy::list
alias dc := deploy::create
alias dd := deploy::delete
