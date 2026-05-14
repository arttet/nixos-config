# Backups

The backup policy is:

```txt
System is reproducible.
Data is valuable.
Back up data, not the full OS image.
```

NixOS generations, the repository flake, and local overlays should be enough to
rebuild the operating system. User data and private local state are the important
backup targets.

## Do Not Back Up

Do not back up:

- `/nix/store`
- system closures
- build artifacts
- VM runtime state
- caches
- `target/`
- `docs/.vitepress/cache`
- `docs/.vitepress/dist`
- `docs/node_modules`

These can be rebuilt or regenerated.

## Back Up

Back up:

- user documents
- projects
- local overlays
- local secrets
- SSH, GPG, and YubiKey-related metadata if applicable
- browser or profile data only if explicitly selected

Local overlays and secrets must remain encrypted at rest in any remote backup.

## Logs

System logs are local by default. They are not backed up automatically.

Collect diagnostic bundles explicitly when needed. Sensitive logs must not be
uploaded unencrypted.

Useful commands:

```sh
journalctl -b
journalctl -b -p warning
journalctl --disk-usage
```

## Future Direction

Automated backups are deferred. Future work may add:

- encrypted backups
- remote untrusted storage
- restic with rclone
- Yandex Disk as a possible remote target
- YubiKey-backed encryption later

This stage only defines policy. It does not implement automated backups.
