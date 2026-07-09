# Workstation Tuning

The workstation tuning layer is a conservative real-hardware baseline. It is
designed for fast console boot, battery-friendly defaults, stable interactive
behavior under memory pressure, SSD-friendly storage behavior, conservative
network performance, predictable Nix rebuilds, and bounded local logs.

The tuning is controlled through `platform.tuning`. The `workstation` profile
enables it by default. The `vm` profile disables it so local QEMU runtime remains
fast, disposable, and simple.

## Goals

- Faster boot without hiding rollback generations.
- Battery-friendly CPU behavior.
- Better memory pressure behavior.
- SSD-friendly filesystem maintenance.
- Conservative network defaults.
- Predictable Nix rebuild resource use.
- Useful but bounded diagnostic logs.

## Boot

The workstation disables `NetworkManager-wait-online`. Login must not wait for
DHCP or Wi-Fi readiness; NetworkManager can continue connecting after the system
has reached the console.

GRUB timeout is set to `2` seconds. This avoids unnecessary normal boot delay
while keeping older generations visible for rollback.

Inspect boot time on installed real hardware:

```sh
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
journalctl -b -p warning
```

The target is fast console boot. After a real install, a healthy target is
approximately 5-15 seconds after GRUB, excluding manual LUKS passphrase entry.

## Power

The headless workstation baseline uses:

```nix
powerManagement.cpuFreqGovernor = "powersave";
```

This is the default because workstation hardware may be a laptop, mini-PC, or
desktop. Battery life, heat, and fan noise are more important than maximum
benchmark performance. Modern CPUs can still boost under load.

The graphical workstation additionally enables the `platform.power` layer. It
uses TLP as the single power policy daemon and disables
`power-profiles-daemon` to avoid competing profile managers. TLP provides the
generic charge threshold policy:

```nix
START_CHARGE_THRESH_BAT0 = 75;
STOP_CHARGE_THRESH_BAT0 = 80;
```

Charge thresholds only take effect on hardware whose EC/sysfs driver exposes
the required controls. On unsupported desktops or laptops, TLP still applies
the generic runtime power profile and leaves battery charge thresholds inert.

UPower provides desktop battery reporting and owns the low-battery action. The
critical policy is intentionally set to power off instead of hibernate:

```nix
services.upower.criticalPowerAction = "PowerOff";
```

Hibernation, hybrid sleep, and suspend-then-hibernate are explicitly disabled
until encrypted resume policy is designed and validated. Lid close suspends on
battery, locks on external power, and is ignored while docked.

## Memory

ZRAM is enabled:

```nix
zramSwap = {
  enable = true;
  memoryPercent = 25;
  algorithm = "zstd";
};
```

This improves behavior under memory pressure, reduces disk swap pressure, and
helps avoid full workstation freezes.

Virtual memory sysctls are conservative:

```nix
boot.kernel.sysctl = {
  "vm.swappiness" = 10;
  "vm.vfs_cache_pressure" = 50;
};
```

Disk swap should not be used too eagerly, and useful filesystem cache should be
kept longer.

`earlyoom` is enabled to avoid total desktop or console lockups under extreme
memory pressure. It is intentionally left with upstream defaults for now.

## Network

The baseline enables BBR with fq:

```nix
boot.kernel.sysctl = {
  "net.core.default_qdisc" = "fq";
  "net.ipv4.tcp_congestion_control" = "bbr";
  "net.ipv4.tcp_fastopen" = 3;
};
```

BBR is a strong modern TCP congestion control default. `fq` pairs well with BBR,
and TCP Fast Open can reduce connection setup cost.

Large TCP buffer tuning is intentionally not configured. Linux defaults are
generally good, and large values are workload-specific. They can increase memory
use or hurt latency if set without measurement.

Validate on real hardware:

```sh
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc
sysctl net.ipv4.tcp_fastopen
```

## Filesystem and SSD

The production storage model uses Btrfs mount options:

```txt
compress=zstd
noatime
discard=async
```

Btrfs compression improves space usage and read efficiency. `noatime` reduces
unnecessary writes. `discard=async` is preferred over synchronous discard on
SSD/NVMe devices.

Periodic trim is enabled with `services.fstrim.enable = true`. This is a safe
maintenance path for long-term SSD behavior.

Automatic snapshots, Timeshift, GRUB snapshot entries, and impermanence are not
enabled yet.

## Nix

Nix uses available local build resources:

```nix
nix.settings = {
  max-jobs = "auto";
  cores = 0;
  auto-optimise-store = true;
  keep-outputs = true;
  keep-derivations = true;
  min-free = 1024 * 1024 * 1024; # 1 GiB
  max-free = 10 * 1024 * 1024 * 1024; # 10 GiB
  experimental-features = [ "nix-command" "flakes" ];
};
```

`ca-derivations` is not enabled. It is experimental and unnecessary for the
current V0/V1 baseline.

## Logs

Journald is bounded:

```ini
Storage=persistent
SystemMaxUse=4G
RuntimeMaxUse=512M
MaxRetentionSec=1month
```

Logs are local by default and are not backed up automatically. Diagnostic
bundles should be collected explicitly. Sensitive logs must not be uploaded or
shared unencrypted.

Inspect logs:

```sh
journalctl -b
journalctl -b -p warning
journalctl --disk-usage
```

## Runtime Validation

After installing on real hardware, run:

```sh
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc
sysctl net.ipv4.tcp_fastopen
sysctl vm.swappiness
sysctl vm.vfs_cache_pressure
journalctl --disk-usage
resolvectl status
resolvectl query example.com
timedatectl status
nft list ruleset
upower -e
upower -d
tlp-stat -b
tlp-stat -s
tlp-stat -p
systemctl status tlp
systemctl status power-profiles-daemon
systemd-analyze cat-config systemd/sleep.conf
```

From the repository, print the generic command list with:

```sh
just workstation runtime-checks
```

Print the graphical workstation power command list with:

```sh
just workstation-gui power-checks
```

## Overrides

Hardware-specific changes should be added through local overlays or future
host-specific modules. Keep the committed baseline generic until a real hardware
target proves that a narrower tuning is needed.

## Deferred

- Zen, XanMod, or custom kernels.
- Performance CPU governor by default.
- Large sysctl tuning blobs.
- TCP buffer tuning.
- IRQ or NUMA tuning.
- Transparent huge pages tuning.
- Dirty ratio tuning.
- Hibernation.
- Automatic snapshots.
- Timeshift.
- GRUB snapshot boot entries.
- TPM, YubiKey, or Secure Boot unlock.
