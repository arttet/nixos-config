build_dir := env("BUILD_DIR", "./target")
vm_state_dir := build_dir / "vm/state"
vm_runtime_dir := build_dir / "vm/runtime"
vm_build_dir := build_dir / "vm-build"
vm_out := vm_build_dir / "result"
vm_runner := vm_out / "bin/run-nixos-vm"
vm_pid_file := vm_runtime_dir / "vm.pid"
vm_log_file := vm_runtime_dir / "vm.log"
vm_ssh_port := env("VM_SSH_PORT", "2222")

[doc('Build the VM')]
[no-cd]
build:
    @echo "Building VM into {{ vm_out }}..."
    if [ -L {{ vm_build_dir }} ]; then rm {{ vm_build_dir }}; fi
    mkdir -p {{ vm_build_dir }}
    nix build .#nixosConfigurations.vm.config.system.build.vm --out-link {{ vm_out }}
    test -x {{ vm_runner }}
    @echo "VM runner: {{ vm_runner }}"

[doc('Run the VM')]
[no-cd]
run: build
    mkdir -p {{ vm_state_dir }}
    runner="$(realpath {{ vm_runner }})"; cd {{ vm_state_dir }} && "$runner"

[doc('Start the VM in the background')]
[no-cd]
daemon: build
    mkdir -p {{ vm_state_dir }} {{ vm_runtime_dir }}
    if [ -f {{ vm_pid_file }} ] && kill -0 "$(cat {{ vm_pid_file }})" 2>/dev/null; then echo "VM is already running with PID $(cat {{ vm_pid_file }})"; exit 0; fi
    runner="$(realpath {{ vm_runner }})"; nohup sh -c 'cd "$1" && exec "$2"' sh "{{ vm_state_dir }}" "$runner" > {{ vm_log_file }} 2>&1 & echo $! > {{ vm_pid_file }}
    @echo "VM started in background."
    @echo "PID file: {{ vm_pid_file }}"
    @echo "Log file: {{ vm_log_file }}"
    @echo "SSH: ssh user@localhost -p {{ vm_ssh_port }}"

[doc('Show VM status')]
[no-cd]
status:
    @if [ -f {{ vm_pid_file }} ] && kill -0 "$(cat {{ vm_pid_file }})" 2>/dev/null; then echo "running pid=$(cat {{ vm_pid_file }}) ssh=user@localhost:{{ vm_ssh_port }} log={{ vm_log_file }}"; else echo "stopped"; fi

[doc('Open an SSH session into the VM')]
[no-cd]
ssh:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null user@localhost -p {{ vm_ssh_port }}

[doc('Stop the background VM')]
[no-cd]
stop:
    @if [ -f {{ vm_pid_file }} ] && kill -0 "$(cat {{ vm_pid_file }})" 2>/dev/null; then kill "$(cat {{ vm_pid_file }})"; echo "Stopping VM pid=$(cat {{ vm_pid_file }})"; else echo "VM is not running."; fi
    @sleep 2
    @if [ -f {{ vm_pid_file }} ] && kill -0 "$(cat {{ vm_pid_file }})" 2>/dev/null; then echo "VM is still running. Use Ctrl+A then x in interactive QEMU, or inspect {{ vm_log_file }}."; else rm -f {{ vm_pid_file }}; echo "VM stopped."; fi

[doc('Validate daemon startup, SSH reachability, and VM network')]
[no-cd]
test: _require_sshpass daemon
    @echo "Waiting for SSH on localhost:{{ vm_ssh_port }}..."
    @for i in $(seq 1 60); do if sshpass -p user ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=2 user@localhost -p {{ vm_ssh_port }} true >/dev/null 2>&1; then echo "SSH is reachable."; break; fi; if [ "$i" = "60" ]; then echo "SSH did not become reachable."; echo "Manual check: just vm ssh"; echo "Inside VM run: curl -4 https://ifconfig.me"; exit 1; fi; sleep 2; done
    sshpass -p user ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 user@localhost -p {{ vm_ssh_port }} 'curl -4 --fail --silent --show-error --output /dev/null https://ifconfig.me'
    @echo "VM daemon, SSH, and VM network validation passed."

[doc('Validate the VM profile without starting QEMU')]
[no-cd]
validate:
    nix eval .#nixosConfigurations.vm.config.services.qemuGuest.enable --apply 'enabled: if enabled then "ok" else throw "vm must enable qemuGuest"'
    nix eval .#nixosConfigurations.vm.config.boot.kernelParams --apply 'params: if builtins.elem "console=ttyS0,115200n8" params then "ok" else throw "vm must include serial console settings"'
    nix eval .#nixosConfigurations.vm.config.virtualisation.vmVariant.virtualisation.graphics --apply 'graphics: if graphics then throw "vm must be headless" else "ok"'
    @echo "VM profile validation passed."

_require_sshpass:
    @if ! command -v sshpass >/dev/null 2>&1; then echo "Missing host dependency: sshpass"; echo "Install it in the Linux environment, then rerun: just vm test"; exit 1; fi

[doc('Remove VM state')]
[no-cd]
clean:
    @echo "Removing VM artifacts from {{ build_dir }}/vm and {{ vm_build_dir }}..."
    if [ -f {{ vm_pid_file }} ] && kill -0 "$(cat {{ vm_pid_file }})" 2>/dev/null; then kill "$(cat {{ vm_pid_file }})"; sleep 2; fi
    rm -rf {{ build_dir }}/vm {{ vm_build_dir }}
