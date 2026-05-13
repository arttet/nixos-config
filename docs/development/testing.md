# Testing

Testing starts with the smallest useful validation.

Run the flake checks and build the guest VM:

```sh
just check
just guest build
```

Validate runtime behavior from a Linux environment that can run QEMU:

```sh
just guest test
```

The guest target is intentionally disposable, so runtime validation can be
repeated without protecting local VM state.

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
