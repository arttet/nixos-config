# Testing

Testing starts with the smallest useful validation.

Run the flake checks, then build the VM and workstation closures explicitly:

```sh
just check
just vm build
just workstation build
just workstation-gui build
```

Validate runtime behavior from a Linux environment that can run QEMU:

```sh
just vm test
```

The VM target is intentionally disposable, so runtime validation can be
repeated without protecting local VM state.

Workstation validation is CI-safe and does not require real hardware:

```sh
just workstation test
just workstation-gui test
```

`workstation-gui test` is CI-safe. It validates the graphical configuration
without launching Hyprland, requiring a GPU, or requiring real hardware.
It still builds the graphical system closure, so CI runs it in a dedicated job
with extra disk cleanup.

For a full local validation pass before opening or merging a change, run:

```sh
just check
just docs build
just vm build
just vm test
just workstation build
just workstation test
just workstation-gui build
just workstation-gui test
```

The workstation storage layout is evaluated with an example disk path only.
Tests do not partition, format, encrypt, or otherwise modify real disks.

## Real Hardware Runtime Checks

After installing the workstation target on real hardware, validate boot and
tuning behavior on the installed machine:

```sh
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
resolvectl status
resolvectl query example.com
timedatectl status
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc
sysctl net.ipv4.tcp_fastopen
sysctl vm.swappiness
sysctl vm.vfs_cache_pressure
nft list ruleset
journalctl --disk-usage
journalctl -b -p warning
doas true
doas id
doas nixos-rebuild switch --flake .#workstation
doas nixos-rebuild switch --rollback
```

The helper command prints the same list without executing hardware-specific
checks:

```sh
just workstation runtime-checks
```

Agents cannot validate the Windows WSL2/QEMU runtime directly. Runtime success is
confirmed by the user after running the commands locally.

## CI Configuration

GitHub Actions uses repository or environment configuration for values that must
not be hardcoded in the workflow.

Variables:

| Name | Used by | Purpose |
| --- | --- | --- |
| `CF_DOCS_PAGES_PROJECT` | `deploy-cf-pages` | Cloudflare Pages project name for the documentation deployment. |

Secrets:

| Name | Used by | Purpose |
| --- | --- | --- |
| `CLOUDFLARE_ACCOUNT_ID` | `deploy-cf-pages` | Cloudflare account identifier used by Wrangler. |
| `CLOUDFLARE_API_TOKEN` | `deploy-cf-pages` | Cloudflare API token used by Wrangler to deploy Pages. |

Derived CI environment:

| Name | Used by | Purpose |
| --- | --- | --- |
| `CF_DOCS_BRANCH` | `deploy-cf-pages` | Pull request preview branch name, formatted as `pr-<number>`. |
| `HAS_CF_ACCOUNT` | `deploy-cf-pages` | Boolean guard for Cloudflare account availability. |
| `HAS_CF_DOCS_PROJECT` | `deploy-cf-pages` | Boolean guard for Cloudflare Pages project availability. |
| `HAS_CF_TOKEN` | `deploy-cf-pages` | Boolean guard for Cloudflare token availability. |

The `deploy-gh-pages` job runs only on pushes to `main` and publishes the docs
artifact through GitHub Pages.

The `deploy-cf-pages` job publishes production docs on pushes to `main`. For
non-fork pull requests, it publishes a Cloudflare Pages preview and updates a
sticky pull request comment with the preview URL.

The `validate` job intentionally keeps `nix flake check` focused on formatting
and lightweight policy checks. VM, headless workstation, and graphical
workstation closures are built in dedicated jobs so the heavy GUI closure is
not built twice on the same GitHub runner.

Nix jobs use Magic Nix Cache to reduce repeated downloads and store pressure.
The graphical workstation job also frees preinstalled runner toolchains before
installing Nix because the full desktop closure includes large browser,
Electron, GUI, and media packages.
