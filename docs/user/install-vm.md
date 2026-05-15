# VM (Local Testing)

The `vm` target is a local headless QEMU mirror of the `workstation` profile. It is designed to be built, booted, discarded, and rebuilt without carrying identity or secrets in the repository.

## Build

```sh
just vm build
```

Expected result:
- Nix builds the VM derivation.
- The VM runner appears under `target/vm-build/result/bin/run-nixos-vm`.

## Interactive Run

```sh
just vm run
```

Expected result:
- QEMU starts in the foreground.
- The VM reaches a console login.
- Login works with `user` / `user`.

To shut down from inside the VM: `sudo poweroff`. If QEMU is attached to the terminal and the VM does not exit cleanly, press `Ctrl+A`, then `x`.

## Daemon Run

```sh
just vm daemon
```

Expected result:
- The VM starts in the background.
- SSH is forwarded to `localhost:2222`.

## Status & SSH

```sh
just vm status
just vm ssh
```

Expected result:
- Status shows running PID and SSH port.
- `just vm ssh` connects to `user@localhost` on port `2222` (password: `user`).

## Test

```sh
just vm test
```

Expected result:
- The daemon starts and SSH becomes reachable.
- The VM can reach the network with `curl -4 https://ifconfig.me`.

The automated test uses `sshpass`. If missing, install it in the host environment.

## Clean

```sh
just vm clean
```

Expected result:
- Runtime state under `target/vm/` and build links are removed.
