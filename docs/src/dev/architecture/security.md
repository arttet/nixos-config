# Security & Network

The workstation security baseline is intentionally small and kernel-focused. It adds conservative hardening without disabling normal NixOS security mitigations or relying on benchmark-oriented kernel parameters.

The module is enabled through:

```nix
platform.security.enable = true;
```

## Kernel Hardening

The baseline enables:

```nix
security.protectKernelImage = true;
security.forcePageTableIsolation = true;
```

Rationale:

- protect the kernel image from accidental or malicious modification paths
- keep page table isolation enabled rather than trading it away for unmeasured performance

### Kernel Policy

The workstation uses:

```nix
boot.kernelPackages = pkgs.linuxPackages_latest;
```

The actual kernel version comes from the pinned `nixpkgs` revision in `flake.lock`. Updating the kernel is therefore a deliberate flake update, not an implicit host mutation.

The project does not use Zen, XanMod, or a custom kernel. Runtime behavior is tuned through the conservative `platform.tuning` module instead of switching to a benchmark-oriented kernel.

Kernel upgrade policy:

- Update `flake.lock` deliberately.
- Build and test `vm`.
- Build `workstation`.
- Apply to real hardware only after reviewing the change.

Rollback uses normal NixOS generations. If a new kernel does not boot, select an older generation from GRUB.

## Sysctl Policy

The baseline sets:

```nix
boot.kernel.sysctl = {
  "kernel.perf_event_paranoid" = 3;
  "user.max_user_namespaces" = 0;
};
```

Rationale:

- restrict unprivileged performance event access
- disable unprivileged user namespaces through the upstream kernel sysctl

These are defaults. Host-specific modules or local overlays can override them deliberately if a measured workflow requires it.

`security.unprivilegedUsernsClone` is intentionally not used. It depends on a kernel behavior that is common in some downstream or hardened kernels, but it is not the right baseline for `pkgs.linuxPackages_latest`. The upstream `user.max_user_namespaces` sysctl is explicit and testable.

## Temporary Files

The workstation keeps `/tmp` volatile:

```nix
boot.tmp.useTmpfs = true;
boot.tmp.cleanOnBoot = true;
```

Rationale:

- temporary files do not persist across reboot
- sensitive transient data is less likely to remain on disk
- cleanup is deterministic and does not depend on manual maintenance

This is a security baseline, not a build-performance optimization. If a host-specific workload needs very large temporary files, override this in the local host layer deliberately.

## Microcode

The workstation enables redistributable firmware and CPU microcode updates for both supported vendor families:

```nix
hardware.enableRedistributableFirmware = true;
hardware.cpu.intel.updateMicrocode = true;
hardware.cpu.amd.updateMicrocode = true;
```

Only the applicable vendor microcode is used on real hardware. Keeping both settings enabled in the reusable workstation profile avoids committing a hardware-specific assumption before the local hardware configuration is known. Microcode updates are part of the Spectre/Meltdown-class mitigation baseline.

## Thunderbolt

Thunderbolt is disabled by default:

```nix
platform.security.disableThunderbolt = true;
boot.blacklistedKernelModules = [ "thunderbolt" ];
```

USB-C is only the connector shape. Thunderbolt and USB4 are separate transports that can expose PCIe-style device access and a larger DMA-facing attack surface. The baseline disables Thunderbolt until a real host has a documented need for a Thunderbolt dock, eGPU, USB4 workflow, or similar hardware.

Ordinary USB devices connected through USB-C are not the same thing as Thunderbolt. A local host module may re-enable Thunderbolt deliberately:

```nix
platform.security.disableThunderbolt = false;
```

That override should be paired with a reviewed hardware inventory and recovery plan.

## Deferred Hardware Policy

Entropy daemons and IOMMU kernel parameters are hardware-sensitive enough to remain deferred for now.

The kernel already provides a modern random subsystem. A dedicated entropy daemon should be added only if real hardware diagnostics show entropy starvation during boot, LUKS unlock, DNS-over-TLS startup, or SSH key work.

IOMMU should be enabled per real host after identifying the CPU/vendor and firmware behavior. Vendor-specific parameters such as `intel_iommu=on` or `amd_iommu=on` do not belong in the generic workstation profile.

## Firewall and Login Policy

The base profile enables the firewall:

```nix
networking.firewall.enable = true;
```

The workstation keeps OpenSSH disabled by default. Root password login is locked by default, and administrative access is expected to come from a local overlay user with `wheel` membership.

The committed placeholder `void` user is not an administrator and must not gain `wheel` or other host privileges.

Nix trusted users are explicit:

```nix
nix.settings.trusted-users = [ "root" "@wheel" ];
```

The real admin user is defined by the local overlay and must be a member of `wheel`. No real username is committed to the public repository.

## Privilege Escalation

The workstation uses `doas` instead of `sudo`:

```nix
security.sudo.enable = false;
security.doas.enable = true;
security.doas.extraRules = [
  {
    groups = [ "wheel" ];
    noPass = false;
    persist = false;
    keepEnv = false;
  }
];
```

Why `doas`:

- smaller privilege escalation surface
- simpler configuration
- easier auditing
- better fit for the minimal workstation baseline

Only `wheel` users may escalate. Passwordless escalation is not allowed. Persistent privilege caching is not allowed. Global environment preservation is not allowed.

## Secure Boot

The workstation enables baseline Secure Boot support with `sbctl` while keeping
GRUB as the bootloader:

```nix
environment.systemPackages = [ pkgs.sbctl ];
```

The GRUB install flow signs EFI artifacts under the EFI System Partition when
local `sbctl` keys exist. Key creation and firmware enrollment remain manual
operations performed after the first successful boot and local repository
rebuild. This avoids automating firmware trust changes while still making EFI
re-signing part of normal rebuilds.

Advanced GRUB hardening, such as GRUB password protection and detached
signature verification for files loaded from `/boot`, is a separate optional
step.

## Journald

The workstation security baseline makes journald persistent:

```nix
services.journald.storage = "persistent";
```

Persistent local logs are part of the operational contract. They make boot, security, and recovery diagnostics available after reboot. Log retention remains bounded by the tuning layer.

Logs may contain sensitive local data. Do not upload diagnostic logs unencrypted.

## DNS Policy

The workstation uses an explicit DNS policy through `systemd-resolved`.

```nix
services.resolved = {
  enable = true;
  dnssec = "true";
  dnsovertls = "true";
  domains = [ "~." ];
  fallbackDns = [
    "1.1.1.1#cloudflare-dns.com"
    "1.0.0.1#cloudflare-dns.com"
  ];
};
```

NetworkManager is configured to hand DNS resolution to `systemd-resolved`.

### Rationale

- Resolver behavior is explicit.
- DNS does not silently depend on ISP defaults.
- Cloudflare DNS is the default baseline.
- DNS-over-TLS is preferred where practical.
- Google DNS is not the preferred default; it may be considered later only as a deliberate fallback.

The VM does not force this workstation DNS policy. QEMU user networking should remain simple and disposable.

## Non-Goals

This baseline does not:

- disable CPU vulnerability mitigations
- add `mitigations=off`
- add cargo-cult kernel parameters
- use passwordless privilege escalation
- use persistent privilege escalation sessions
- enable USBGuard before a real device allowlist exists
- enable vendor-specific IOMMU parameters before real hardware validation
- add an entropy daemon without measured entropy pressure
- enable kernel lockdown mode
- enable TPM or YubiKey unlock
- replace threat modeling with generic sysctl blobs

## Homelab Service Boundary

The Pi target does not import service credentials into Nix. The AdGuard administrator bcrypt
verifier is generated interactively on the device and stored root-only under `/persist`; complete
WireGuard profiles remain under the administrator's persistent home and are activated explicitly.
Samba credentials are provisioned once through interactive `smbpasswd` and retained only in the
passdb on encrypted `/srv`. The AdGuard
configuration renderer runs as root and writes a read-only runtime configuration, so UI changes are
not a source of durable state.

Only SSH is admitted by the host firewall with rate limiting. DNS, AdGuard UI, Samba, Caddy, Forgejo SSH,
and diagnostic rules require the configured LAN interface or IPv4 LAN source CIDR. Podman workload
backends bind to localhost and are reached through Caddy. Nix installs
WireGuard tools but does not validate or activate user-managed profiles; operators must review
`AllowedIPs` before activation.
