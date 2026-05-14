build_dir := env("BUILD_DIR", "./target")
workstation_build_dir := build_dir / "workstation"
workstation_out := workstation_build_dir / "result"

[doc('Build the workstation system closure')]
[no-cd]
build:
    @echo "Building workstation system closure into {{ workstation_out }}..."
    if [ -L {{ workstation_build_dir }} ]; then rm {{ workstation_build_dir }}; fi
    mkdir -p {{ workstation_build_dir }}
    nix build .#nixosConfigurations.workstation.config.system.build.toplevel --out-link {{ workstation_out }}
    test -e {{ workstation_out }}
    @echo "Workstation closure: {{ workstation_out }}"

[doc('Validate the workstation profile')]
[no-cd]
test: build
    nix eval .#nixosConfigurations.workstation.config.services.qemuGuest.enable --apply 'enabled: if enabled then throw "workstation must not enable qemuGuest" else "ok"'
    nix eval .#nixosConfigurations.workstation.config.boot.kernelParams --apply 'params: if builtins.elem "console=ttyS0,115200n8" params then throw "workstation must not include VM serial console settings" else "ok"'
    @echo "Workstation evaluation, closure build, and VM-only separation passed."
