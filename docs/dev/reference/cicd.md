# 🛠️ CI/CD Pipeline

Every contribution to this repository is automatically validated through a GitHub Actions pipeline. This ensures that the configuration remains buildable, correctly formatted, and technically sound.

## 🧱 Automated Checks

The CI pipeline runs the following checks on every Pull Request:

| Check                | Tool                | Description                                                                       |
| :------------------- | :------------------ | :-------------------------------------------------------------------------------- |
| **Repository Check** | `just check`        | Runs the production validation gate used by local development and CI.             |
| **Formatting**       | `checks.formatting` | Verifies that all `.nix` files follow the repository style through `treefmt-nix`. |
| **Flake Check**      | `nix flake check`   | Validates flake syntax, static policy checks, `statix`, and `deadnix`.            |
| **Nix Lint**         | `statix`            | Rejects common Nix anti-patterns and suspicious expressions.                      |
| **Dead Code**        | `deadnix`           | Rejects unused Nix bindings and arguments.                                        |
| **Documentation**    | `just docs build`   | Ensures the VitePress documentation builds without broken links.                  |
| **VM Validation**    | `just vm test`      | Boots the configuration in a headless QEMU VM to verify core services.            |

## 🚀 Job Strategy

The CI workflow is optimized for efficiency and runner disk space:

- **Dedicated Closures**: VM, headless workstation, and graphical workstation closures are built in dedicated jobs. This prevents the heavy GUI closure from being built twice on the same runner.
- **Resource Management**: The graphical workstation job frees preinstalled runner toolchains (Android, .NET, etc.) before installing Nix to ensure enough disk space for large browser and media packages.
- **Caching**: Nix jobs use **Magic Nix Cache** to reduce repeated downloads and store pressure.
- **Headless Testing**: `workstation-gui test` is CI-safe. It validates the desktop profile without launching Hyprland or requiring GPU acceleration.

## 📦 Deployment Workflow

Once a Pull Request is merged into `main`:

1. **GitHub Pages**: The documentation is automatically built and deployed.
2. **Cloudflare Pages**: Production docs are published. For non-fork PRs, a preview environment is created and a link is posted in the PR comments.
3. **Lockfile Persistence**: The `flake.lock` is tracked to ensure reproducible builds for all users.

## 🌙 Nightly Workflow

The `Nightly` workflow runs daily after scheduled CI has warmed the Nix cache.
It updates `flake.lock`, checks out configured dotfiles, runs the installer in
dry-run mode to generate a fake `platform.state` user, and validates the
`desktop` target against that generated state.

Scheduled runs never push changes. Manual runs open a `flake.lock` update Pull
Request only when the `deploy` input is `true`, the desktop validation passes,
and `flake.lock` changed.

## ⚙️ CI Configuration

GitHub Actions uses repository or environment configuration for sensitive values or project-specific flags.

### Variables

| Name                      | Purpose                                                                  |
| :------------------------ | :----------------------------------------------------------------------- |
| `CF_DOCS_PAGES_PROJECT`   | Cloudflare Pages project name for documentation deployment.              |
| `NIGHTLY_DOTFILES_REPO`   | Required `owner/repo` repository used as nightly fake-user dotfiles.     |
| `NIGHTLY_DOTFILES_REF`    | Optional dotfiles ref; defaults to `main`.                               |
| `NIGHTLY_DOTFILES_MODULE` | Optional relative Home Manager module path inside the dotfiles checkout. |
| `NIGHTLY_DOTFILES_ROOT`   | Optional relative dotfiles root path inside the checkout.                |
| `NIGHTLY_DOTFILES_LINKS`  | Optional comma-separated relative dotfile link paths.                    |

### Secrets

| Name                    | Purpose                                       |
| :---------------------- | :-------------------------------------------- |
| `CLOUDFLARE_ACCOUNT_ID` | Account identifier used by Wrangler.          |
| `CLOUDFLARE_API_TOKEN`  | API token used to deploy to Cloudflare Pages. |

## 🧪 Running Validation Locally

You should always run the core validation suite before pushing your changes:

```sh
just check
```

This meta-recipe runs the same Nix validation gate as CI: `nix flake check`.
The flake check includes formatting, `statix`, `deadnix`, and repository policy
assertions.
