# VM

The `vm` target is a local headless QEMU mirror of the `workstation` profile. It
is designed to be built, booted, discarded, and rebuilt without carrying identity
or secrets in the repository.

## Build

```sh
just vm build
```

Expected result:

- Nix builds the VM derivation.
- The VM runner appears under `target/vm-build/result/bin/run-nixos-vm`.
- Existing Nix store paths are reused when possible.

## Interactive Run

```sh
just vm run
```

Expected result:

- QEMU starts in the foreground.
- The VM reaches a console login.
- Login works with `user` / `user`.

To shut down from inside the VM:

```sh
sudo poweroff
```

If QEMU is attached to the terminal and the VM does not exit cleanly, press
`Ctrl+A`, then `x`.

## Daemon Run

```sh
just vm daemon
```

Expected result:

- The VM starts in the background.
- PID and log files are written under `target/vm/runtime/`.
- SSH is forwarded to `localhost:2222`.

## Status

```sh
just vm status
```

Expected result when running:

```txt
running pid=<pid> ssh=user@localhost:2222 log=target/vm/runtime/vm.log
```

Expected result when stopped:

```txt
stopped
```

## SSH

```sh
just vm ssh
```

Expected result:

- SSH connects to `user@localhost` on port `2222`.
- Password is `user`.

Manual equivalent:

```sh
ssh user@localhost -p 2222
```

## Test

```sh
just vm test
```

Expected result:

- The daemon starts if it is not already running.
- SSH becomes reachable on `localhost:2222`.
- The VM can reach the network with `curl -4 https://ifconfig.me`.

The automated test uses `sshpass` because the local VM keeps a generic
password-based test identity. If `sshpass` is missing, install it in the Linux
host environment and rerun the command.

## Stop

```sh
just vm stop
```

Expected result:

- The background VM process is terminated.
- The PID file is removed once the process is gone.

## Clean

```sh
just vm clean
```

Expected result:

- Runtime state under `target/vm/` is removed.
- The VM build output link under `target/vm-build/` is removed.
- The Nix store is not cleaned.

## Network Notes

The VM uses QEMU user-mode networking. TCP workflows such as SSH and HTTPS are
the runtime acceptance signal.

ICMP ping may fail even when DNS and TCP networking work. Prefer:

```sh
curl -4 https://ifconfig.me
```
