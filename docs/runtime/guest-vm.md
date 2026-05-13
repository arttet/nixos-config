# Guest VM

The `guest` target is a minimal headless NixOS VM for local infrastructure
validation. It is designed to be built, booted, discarded, and rebuilt without
carrying identity or secrets in the repository.

## Build

```sh
just guest build
```

Expected result:

- Nix builds the VM derivation.
- The VM runner appears under `target/guest-vm/result/bin/run-nixos-vm`.
- Existing Nix store paths are reused when possible.

## Interactive Run

```sh
just guest run
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
just guest daemon
```

Expected result:

- The VM starts in the background.
- PID and log files are written under `target/guest/runtime/`.
- SSH is forwarded to `localhost:2222`.

## Status

```sh
just guest status
```

Expected result when running:

```txt
running pid=<pid> ssh=user@localhost:2222 log=target/guest/runtime/guest.log
```

Expected result when stopped:

```txt
stopped
```

## SSH

```sh
just guest ssh
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
just guest test
```

Expected result:

- The daemon starts if it is not already running.
- SSH becomes reachable on `localhost:2222`.
- The guest can reach the network with `curl -4 https://ifconfig.me`.

The automated test uses `sshpass` because milestone 002 keeps the guest identity
generic and password-based. If `sshpass` is missing, install it in the Linux host
environment and rerun the command.

## Stop

```sh
just guest stop
```

Expected result:

- The background VM process is terminated.
- The PID file is removed once the process is gone.

## Clean

```sh
just guest clean
```

Expected result:

- Runtime state under `target/guest/` is removed.
- The VM build output link under `target/guest-vm/` is removed.
- The Nix store is not cleaned.

## Network Notes

The guest uses QEMU user-mode networking. TCP workflows such as SSH and HTTPS are
the runtime acceptance signal.

ICMP ping may fail even when DNS and TCP networking work. Prefer:

```sh
curl -4 https://ifconfig.me
```
