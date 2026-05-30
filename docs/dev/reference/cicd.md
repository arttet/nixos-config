# CI/CD Pipeline

Every contribution is validated through GitHub Actions. CI is split into small
quality gates first, then heavier Nix profile builds, then documentation
deployment.

## Automated Checks

| Check          | Tool                     | Description                                                            |
| :------------- | :----------------------- | :--------------------------------------------------------------------- |
| Format         | `dprint`, `just`         | Verifies source formatting and Justfile formatting.                    |
| Lint           | `yamllint`, `actionlint` | Verifies YAML and GitHub Actions syntax.                               |
| Nix check      | `nix flake check`        | Runs Nix formatting, schema checks, `statix`, `deadnix`, and policies. |
| Security       | TruffleHog, Trivy        | Scans for verified or unknown secrets and common security issues.      |
| Antivirus      | ClamAV                   | Scans the repository for malware signatures.                           |
| Documentation  | Bun, VitePress, Lychee   | Audits docs dependencies, builds docs, and checks generated links.     |
| Installer      | Nushell tests            | Validates installer and generated local-state contracts.               |
| Profile builds | Nix                      | Builds VM, workstation, and desktop closures.                          |

## Job Strategy

- **Single policy gate**: `nix flake check` runs policy checks once. Profile
  jobs build closures only and do not repeat `vm-policy`, `workstation-policy`,
  or `desktop-policy`.
- **Dedicated closures**: VM, headless workstation, and desktop closures are
  built in separate jobs so the heavy GUI closure is not built twice on the
  same runner.
- **Resource management**: the desktop job frees preinstalled runner toolchains
  before installing Nix.
- **Caching**: documentation builds use the Bun package cache. Nix jobs rely on
  `cache.nixos.org`; add an authenticated binary cache such as Cachix or Attic
  before enabling repository-level Nix write-back caching.
- **Scheduled refresh**: `Daily Cache Cleanup` clears GitHub Actions caches at
  01:50 UTC. CI runs at 02:00 UTC to rebuild fresh caches.

## Deployment Workflow

Once a pull request is merged into `main`:

1. GitHub Pages documentation is deployed from the CI docs artifact.
2. Cloudflare Pages production docs are deployed when Cloudflare configuration
   is available.
3. Non-fork pull requests receive a Cloudflare preview comment when Cloudflare
   configuration is available.

## Nightly Workflow

The `Nightly` workflow runs daily after scheduled CI. It updates `flake.lock`,
checks out configured dotfiles, runs the installer in dry-run mode to generate a
fake `platform.state` user, and validates the `desktop` target against that
generated state.

Scheduled runs never push changes. Manual runs open a `flake.lock` update pull
request only when the `deploy` input is `true`, desktop validation passes, and
`flake.lock` changed.

## CI Configuration

GitHub Actions uses repository variables and secrets for project-specific
deployment and nightly inputs.

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

## Running Validation Locally

Run the core validation suite before pushing:

```sh
just check
```

This runs `nix flake check`, including formatting, `statix`, `deadnix`, schema
checks, and repository policy assertions.
