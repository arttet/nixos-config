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
    just --fmt
    nix fmt
    @echo "✅ Code formatted!"

[doc('Run repository checks')]
[group('Development')]
check:
    nix flake check

[doc('Run local script tests')]
[group('Development')]
test:
    nu scripts/tests/install.nu

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
