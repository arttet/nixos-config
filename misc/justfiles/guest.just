build_dir := env("BUILD_DIR", "./target")
guest_state_dir := build_dir / "guest/state"
guest_runtime_dir := build_dir / "guest/runtime"
guest_vm_dir := build_dir / "guest-vm"
guest_vm_out := guest_vm_dir / "result"
guest_vm_runner := guest_vm_out / "bin/run-nixos-vm"
guest_pid_file := guest_runtime_dir / "guest.pid"
guest_log_file := guest_runtime_dir / "guest.log"
guest_ssh_port := env("GUEST_SSH_PORT", "2222")

[doc('Build the guest VM')]
[no-cd]
build:
    @echo "Building guest VM into {{ guest_vm_out }}..."
    if [ -L {{ guest_vm_dir }} ]; then rm {{ guest_vm_dir }}; fi
    mkdir -p {{ guest_vm_dir }}
    nix build .#nixosConfigurations.guest.config.system.build.vm --out-link {{ guest_vm_out }}
    test -x {{ guest_vm_runner }}
    @echo "Guest VM runner: {{ guest_vm_runner }}"

[doc('Run the guest VM')]
[no-cd]
run: build
    mkdir -p {{ guest_state_dir }}
    runner="$(realpath {{ guest_vm_runner }})"; cd {{ guest_state_dir }} && "$runner"

[doc('Start the guest VM in the background')]
[no-cd]
daemon: build
    mkdir -p {{ guest_state_dir }} {{ guest_runtime_dir }}
    if [ -f {{ guest_pid_file }} ] && kill -0 "$(cat {{ guest_pid_file }})" 2>/dev/null; then echo "Guest VM is already running with PID $(cat {{ guest_pid_file }})"; exit 0; fi
    runner="$(realpath {{ guest_vm_runner }})"; nohup sh -c 'cd "$1" && exec "$2"' sh "{{ guest_state_dir }}" "$runner" > {{ guest_log_file }} 2>&1 & echo $! > {{ guest_pid_file }}
    @echo "Guest VM started in background."
    @echo "PID file: {{ guest_pid_file }}"
    @echo "Log file: {{ guest_log_file }}"
    @echo "SSH: ssh user@localhost -p {{ guest_ssh_port }}"

[doc('Show guest VM status')]
[no-cd]
status:
    @if [ -f {{ guest_pid_file }} ] && kill -0 "$(cat {{ guest_pid_file }})" 2>/dev/null; then echo "running pid=$(cat {{ guest_pid_file }}) ssh=user@localhost:{{ guest_ssh_port }} log={{ guest_log_file }}"; else echo "stopped"; fi

[doc('Open an SSH session into the guest VM')]
[no-cd]
ssh:
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null user@localhost -p {{ guest_ssh_port }}

[doc('Stop the background guest VM')]
[no-cd]
stop:
    @if [ -f {{ guest_pid_file }} ] && kill -0 "$(cat {{ guest_pid_file }})" 2>/dev/null; then kill "$(cat {{ guest_pid_file }})"; echo "Stopping guest VM pid=$(cat {{ guest_pid_file }})"; else echo "Guest VM is not running."; fi
    @sleep 2
    @if [ -f {{ guest_pid_file }} ] && kill -0 "$(cat {{ guest_pid_file }})" 2>/dev/null; then echo "Guest VM is still running. Use Ctrl+A then x in interactive QEMU, or inspect {{ guest_log_file }}."; else rm -f {{ guest_pid_file }}; echo "Guest VM stopped."; fi

[doc('Validate daemon startup, SSH reachability, and guest network')]
[no-cd]
test: daemon
    @if ! command -v sshpass >/dev/null 2>&1; then echo "Missing host dependency: sshpass"; echo "Install it in the Linux environment, then rerun: just guest test"; exit 1; fi
    @echo "Waiting for SSH on localhost:{{ guest_ssh_port }}..."
    @for i in $(seq 1 60); do if sshpass -p user ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=2 user@localhost -p {{ guest_ssh_port }} true >/dev/null 2>&1; then echo "SSH is reachable."; break; fi; if [ "$i" = "60" ]; then echo "SSH did not become reachable."; echo "Manual check: just guest ssh"; echo "Inside VM run: curl -4 https://ifconfig.me"; exit 1; fi; sleep 2; done
    sshpass -p user ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 user@localhost -p {{ guest_ssh_port }} 'curl -4 --fail --silent --show-error https://ifconfig.me >/dev/null'
    @echo "Guest daemon, SSH, and guest network validation passed."

[doc('Remove guest VM state')]
[no-cd]
clean:
    @echo "Removing guest VM artifacts from {{ build_dir }}/guest and {{ guest_vm_dir }}..."
    if [ -f {{ guest_pid_file }} ] && kill -0 "$(cat {{ guest_pid_file }})" 2>/dev/null; then kill "$(cat {{ guest_pid_file }})"; sleep 2; fi
    rm -rf {{ build_dir }}/guest {{ guest_vm_dir }}
