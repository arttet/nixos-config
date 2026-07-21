# Raspberry Pi 5 Homelab

The `homelab-rpi5` target produces an ephemeral-root microSD image for a headless Raspberry Pi 5.
The SD root partition is mounted at `/persist`; `/nix`, `/home`, the SSH host identity, and minimal
machine state survive reboot, while `/`, `/var`, `/tmp`, and `/root` are volatile. An existing LUKS2
SSD is unlocked manually and mounted at `/srv`; the configuration never formats or repairs it.

`/home` is intentionally persistent, so deliberately saved user files remain available. Homelab
users always receive the stable Bash from the Raspberry Pi package set; Nushell is not installed as
an interactive user package. Bash history defaults to per-user runtime storage to reduce incidental
SD writes, but applications and files under `/home` can still wear the card and must be managed
accordingly.

SSH, explicitly activated user-managed WireGuard profiles, and AdGuard Home DNS remain available
without the SSD. Samba, Beszel, Forgejo, OpenSpeedTest, Gatus, and Vikunja start only after storage
unlock, since all persist their state to the encrypted `/srv` volume rather than the SD card.
Service ports other than SSH are restricted to the configured LAN CIDR.

## Prepare local identity

Create a dedicated key outside this repository if one does not already exist:

```sh
ssh-keygen -t ed25519 -a 64 -f ~/.ssh/homelab-rpi5
```

The private file `~/.ssh/homelab-rpi5` remains on the workstation. Only the path to
`~/.ssh/homelab-rpi5.pub` is used by Nix. Create an external platform-state file such as
`/etc/nixos/local/homelab-rpi5.json`:

```json
{
  "schemaVersion": 1,
  "host": {
    "hostname": "homelab-rpi5",
    "timezone": "Asia/Dubai"
  },
  "users": [
    {
      "name": "admin",
      "description": "Homelab Administrator",
      "isAdmin": true,
      "extraGroups": [],
      "shell": "bash",
      "authorizedKeysFile": "/home/example/.ssh/homelab-rpi5.pub",
      "sources": null
    }
  ],
  "homelab": {
    "lanCidr": "192.168.0.0/24",
    "services": {
      "wireguard": true,
      "adguard": true,
      "beszel": true,
      "caddy": true,
      "forgejo": true,
      "forgejoRunner": true,
      "gatus": true,
      "podman": true,
      "samba": true,
      "openspeedtest": true,
      "vikunja": true
    },
    "domain": "pi.lan",
    "lanInterface": "end0",
    "forgejo": {
      "domain": "git.pi.lan",
      "runnerEnvironmentFile": "/srv/secrets/forgejo-runner.env"
    },
    "openspeedtest": {
      "domain": "speed.pi.lan"
    },
    "beszel": {
      "domain": "monitor.pi.lan",
      "agentEnvironmentFile": "/srv/secrets/beszel-agent.env"
    },
    "storage": {
      "luksDevice": "/dev/disk/by-uuid/REPLACE-WITH-LUKS-UUID",
      "mapperName": "homelab-data",
      "fileSystemType": "ext4"
    },
    "adguard": {
      "upstreamDns": ["https://REPLACE-WITH-UPSTREAM/dns-query"]
    },
    "gatus": {
      "domain": "status.pi.lan"
    },
    "vikunja": {
      "domain": "tasks.pi.lan",
      "environmentFile": "/srv/secrets/vikunja.env"
    }
  }
}
```

Replace all example identity and paths. `authorizedKeysFile` must be absolute and must refer to a
public key or `authorized_keys` file. Never point it at the private key.

Every entry under `homelab.services` is opt-in and defaults to `false`. Start with all entries disabled
to validate SSH, the SD-root recovery boot, and storage unlock. Enable AdGuard, Samba, Beszel, Caddy,
Podman, Forgejo, OpenSpeedTest, Gatus, and Vikunja one at a time. Enabling WireGuard only installs `wg`
and `wg-quick`; profiles remain user-managed outside Nix.

AdGuard's administrator bcrypt verifier is generated interactively on the Pi with
`doas homelab-adguard-password-set` and stored root-only at
`/persist/etc/homelab/adguard-password.hash`. Samba's passdb is provisioned once with interactive
`smbpasswd` after storage unlock. Neither credential is part of platform state or the Nix store.

Vikunja needs a persistent signing secret so login sessions survive service restarts; without one
it generates a random secret at every start and invalidates every session. Generate it once and
write it to the runtime env file after storage unlock:

```sh
printf 'VIKUNJA_SERVICE_SECRET=%s\n' "$(openssl rand -hex 32)" > /srv/secrets/vikunja.env
chmod 600 /srv/secrets/vikunja.env
```

Use `VIKUNJA_SERVICE_SECRET` (`service.secret`), not the older `VIKUNJA_SERVICE_JWTSECRET`
(`service.jwtsecret`): Vikunja 2.3.0 logs `both service.secret and service.jwtsecret are set. Using
service.secret` and ignores the deprecated key entirely if both are present.

As with `/srv/secrets/forgejo-runner.env` and `/srv/secrets/beszel-agent.env`, Nix does not read this
file's contents; it only passes its absolute path to systemd.

Store complete WireGuard profiles under the administrator's persistent home, for example
`/home/<admin>/VPN/WireGuard/`. Restrict the directory to mode `0700` and profiles to `0600`, then
start a reviewed profile explicitly:

```sh
doas wg-quick up /home/<admin>/VPN/WireGuard/<profile>.conf
doas wg show
doas wg-quick down /home/<admin>/VPN/WireGuard/<profile>.conf
```

Nix does not read, copy, validate, or automatically start these profiles. Review `AllowedIPs` before
activation because an uploaded profile may change the default route.

## Build and flash

```sh
export NIX_CONFIG_LOCAL_STATE=/absolute/path/to/homelab-rpi5.json
just homelab check
just homelab image-dry-run
just homelab image-kernel-cache-check
just homelab image
lsblk -o NAME,PATH,SIZE,MODEL,TRAN,TYPE,MOUNTPOINTS
just homelab flash /dev/sdX
```

Use `just homelab image-dry-run` before a full image build when changing the flake lock. It shows
which derivations would be fetched and which would be built locally. Use
`just homelab image-kernel-cache-check` to fail if the Raspberry Pi kernel or ZFS kernel modules would
be built locally. Small generated NixOS derivations such as `/etc`, activation scripts, and the final
image closure are expected to build locally.

The flash helper accepts only a whole `/dev/sdX` or `/dev/mmcblkN` device, rejects mounted media,
shows device metadata, and requires the complete path to be typed again. It never unmounts media.

`/dev/sdX` is only an example. Selecting the wrong device destroys all data on that device.

If the helper is unavailable, the manual equivalent is:

```sh
lsblk -o NAME,PATH,SIZE,MODEL,TRAN,TYPE,MOUNTPOINTS
zstd -dc target/homelab-rpi5-image/sd-image/*.img.zst \
  | doas dd of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

The helper is recommended because the manual command has fewer safety checks.

## First boot

1. Safely remove the microSD card and insert it into a powered-off Raspberry Pi 5.
2. Connect Ethernet to a network that provides DHCP, then connect power.
3. Wait up to five minutes. First boot may expand the persistent SD partition and generate the
   persistent SSH host identity.
4. Resolve the host with `getent hosts homelab-rpi5.local`. If that fails, inspect router DHCP
   leases, then use `ip neigh` and check TCP port 22 on likely addresses.
5. Obtain the SSH host-key fingerprint from a trusted local-network or console view. Compare it
   before accepting the key on first connection.
6. Connect with `ssh -i ~/.ssh/homelab-rpi5 admin@homelab-rpi5.local`.

From the workstation, get the normal operational summary with one SSH connection:

```sh
just homelab status
```

The command reports system, root, persistent storage, failed units, and enabled service state without
printing credentials, WireGuard keys, peer data, or logs. It also reports CPU temperature and
governor, load, memory and swap use, and Ethernet link speed plus cumulative error/drop counters. A
locked or absent optional SSD is healthy; SSD-backed services are reported as `waiting-storage`.
Exit status `1` means that the server was reached but an unexpected failure was found. SSH normally
returns `255` when the host is unreachable.

When `homelab.services.iperf3` is enabled, measure both directions from the workstation:

```sh
just homelab benchmark-network
just homelab benchmark-network 20 4
```

The first argument is duration per direction in seconds and the second is the number of parallel
streams. The command resolves the actual server hostname through `ssh -G`, verifies the remote
`iperf3.service`, then runs direct and reverse tests. It does not modify server configuration.

For initial hardware acceptance, also run these checks on the Pi:

```sh
uname -m
nixos-version
hostnamectl hostname
ip -brief address
findmnt / /persist /nix /home /boot/firmware
findmnt -no FSTYPE /
systemctl is-system-running
systemctl --failed
systemctl status adguardhome
wg show
journalctl --disk-usage
doas true
```

Before storage unlock, `/` must be the SD ext4 root; SSH and AdGuard must work; `/srv` must not be
mounted; Podman workloads, Samba, Beszel, Gatus, and Vikunja must be inactive without failed units.
A user-managed WireGuard profile works only after explicit activation. `doas true` must not prompt
for a password.

## Unlock existing SSD storage

Before enabling Samba, Forgejo, or other `/srv`-backed workloads, make and verify backups of the LUKS header and valuable SSD data. The
configured device must be the LUKS container's stable `/dev/disk/by-uuid/...` path and the declared
filesystem must already exist inside it.

From the workstation, run:

```sh
just homelab storage-unlock
```

This opens an interactive SSH TTY, runs `cryptsetup open`, verifies the filesystem type, mounts it at
`/srv`, bind-mounts `/srv/system/log/journal` at `/var/log/journal`, flushes early volatile logs, and
starts `homelab-storage.target`. Re-running it is safe. It never runs `luksFormat`, `mkfs`, `fsck`, or
another repair operation.

After unlock, verify:

```sh
just homelab status
findmnt /srv /var/log/journal
systemctl is-active podman-forgejo podman-openspeedtest samba-smbd beszel beszel-agent gatus vikunja
systemctl --failed
journalctl --disk-usage
```

The encrypted `/srv` layout is intentionally split by responsibility:

```text
/srv/system/log/journal          persistent system journal
/srv/data/forgejo                Forgejo application state
/srv/data/forgejo-runner         Forgejo runner state and registration
/srv/data/beszel                 Beszel Hub and agent state
/srv/data/vikunja                Vikunja application state (SQLite DB + attached files)
/srv/data/gatus                  Gatus check-history SQLite database
/srv/secrets                     runtime-only environment files
/srv/samba/state                 Samba internal state and passdb
/srv/samba/shares/private        writable private SMB share
```

Nix does not read secret values from `/srv/secrets`; it only passes absolute runtime paths from the
local JSON state to systemd and Podman units.

When enabling Samba for the first time, provision or rotate its password interactively after unlock:

```sh
ssh -t "$NIXOS_TARGET_HOST" 'doas smbpasswd -a samba'
```

The resulting NT hash stays in the Samba passdb under `/srv/samba/state`; the plaintext password is not
stored in platform state, the Nix store, or process arguments.

Samba exposes only the `private` share, requires user `samba`, SMB3, and encryption. Beszel,
Forgejo, OpenSpeedTest, Gatus, and Vikunja are exposed through Caddy; backend ports stay bound to
localhost.

### Trust the Caddy local CA

Caddy keeps the private CA key on the Pi. Only its public root certificate belongs in the repository.
After the first Caddy start, copy that certificate to the workstation and verify its fingerprint before
rebuilding:

```sh
scp admin@homelab-rpi5.local:/persist/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt \
  certs/caddy-homelab-ca.crt
openssl x509 -in certs/caddy-homelab-ca.crt -noout -sha256 -fingerprint
just desktop build
```

Compare the fingerprint with the same `openssl x509` command run on the Pi through the trusted SSH
session. The desktop profile installs the root system-wide and into Firefox-compatible browsers; the
homelab profile installs it for command-line clients on the Pi. Never copy Caddy's `root.key`.

If Caddy's CA is regenerated, replace the committed public certificate, repeat the fingerprint check,
and rebuild both the desktop and homelab. Existing certificates remain untrusted until their clients
receive the replacement root.

## NixOS release upgrade

The Raspberry Pi system follows the `nixpkgs` package set pinned by `nixos-raspberrypi`, not the
repository's workstation `nixpkgs`. Do not force it to use a newer root package set only to align
release numbers. Raspberry Pi 5 boot depends on the matching firmware, device tree, bootloader, and
vendor kernel modules from the Raspberry Pi package stack.

For the 26.05 line, wait until `nixos-raspberrypi` updates its own `nixpkgs` input. Then update the
flake lock, build a new SD image, deploy with the default remote `test` mode, complete the hardware
checks, and only then use `just homelab deploy switch`.

An installed Pi keeps `system.stateVersion = "25.11"` permanently as its migration baseline. After a
successful future upgrade, `nixos-version` reports 26.05 while `system.stateVersion` remains 25.11.

From the workstation, verify both prohibited paths fail with `Permission denied`:

```sh
ssh -o PubkeyAuthentication=no \
  -o PreferredAuthentications=password \
  admin@homelab-rpi5.local
ssh root@homelab-rpi5.local
```

These commands validate runtime behavior on real hardware; a successful image build alone does not.

## Deploy later generations

Test a generation before making it the boot default:

Set the local-only values in the repository `.env`; the root `justfile` loads this file:

```dotenv
NIX_CONFIG_LOCAL_STATE=/absolute/path/to/homelab-rpi5.json
NIXOS_HOST=homelab-rpi5
NIXOS_TARGET_HOST=admin@homelab-rpi5.local
```

```sh
just homelab deploy
```

Confirm Ethernet and SSH still work, then persist it explicitly:

```sh
just homelab deploy switch
```

The Just recipe runs `nixos-rebuild` directly with the selected flake target, local builds,
`--target-host`, and `--sudo`. Test activation is the default; `switch` is explicit.

Check the deployed homelab configuration version on the Pi:

```sh
cat /etc/homelab-version
printf '%s\n' "$HOMELAB_CONFIG_VERSION"
```

The value has the form `0.1.0-<git-revision>` or `0.1.0-dev` for an uncommitted build.

Systems installed from an older image with `security.sudo.enable = false` need a one-time bootstrap.
Either flash a newly built image or activate the first sudo-enabled generation through the existing
`doas` access:

```sh
export NIX_CONFIG_LOCAL_STATE=/absolute/path/to/homelab-rpi5.json
export NIXOS_HOST=homelab-rpi5
export NIXOS_TARGET_HOST=admin@homelab-rpi5.local
system=$(nix build --impure \
  ".#nixosConfigurations.${NIXOS_HOST}.config.system.build.toplevel" \
  --no-link --print-out-paths)
nix copy --to "ssh-ng://$NIXOS_TARGET_HOST" "$system"
ssh "$NIXOS_TARGET_HOST" "doas $system/bin/switch-to-configuration switch"
```

After that one-time migration, use only `just homelab deploy` and `just homelab deploy switch`.

To roll back manually:

```sh
ssh -i ~/.ssh/homelab-rpi5 admin@homelab-rpi5.local
nix-env --list-generations -p /nix/var/nix/profiles/system
doas /nix/var/nix/profiles/system-<N>-link/bin/switch-to-configuration switch
```
