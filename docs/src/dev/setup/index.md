# 🏗️ Local Environment

To contribute to this platform, you need a local development environment capable of running **Nix** and **QEMU**.

One of the core strengths of this repository is that it is **distro-agnostic**. You do not need to be running NixOS to build, test, or modify the configuration.

## Repository Tools and Documentation

Install [mise](https://mise.jdx.dev/getting-started.html), review `mise.toml`,
then trust this checkout and install its pinned tools:

```sh
mise trust
mise exec aube@2.9.0 node@26.7.0 -- just docs install
mise exec aube@2.9.0 node@26.7.0 -- just docs build
```

These commands select the documentation toolchain without changing the versions in mise.toml. Documentation uses aube 2.9.0 and Node.js; Nix and QEMU are needed for system builds and VM testing, respectively.

Documentation sources live in `docs/src/`; VitePress configuration lives in
`docs/.vitepress/`. A successful build writes `docs/.vitepress/dist/` and rejects
unresolved internal page links. For local editing, run `mise exec aube@2.9.0 node@26.7.0 -- just docs dev`. The just recipes require a POSIX shell; on Windows, use Git Bash or WSL.

### Updating Documentation Dependencies

```sh
mise exec aube@2.9.0 node@26.7.0 -- just docs update
mise exec aube@2.9.0 node@26.7.0 -- just docs audit
mise exec aube@2.9.0 node@26.7.0 -- just docs install
mise exec aube@2.9.0 node@26.7.0 -- just docs build
```

Review and commit `docs/package.json` and `docs/aube-lock.yaml` together.
The install command uses `--frozen-lockfile` and must reject manifest drift.
The former Bun Dependabot entry is removed; review documentation dependency
updates explicitly with aube. No Bun lockfile is maintained.

The "minimatch" override keeps the documentation dependency graph above the
version affected by GHSA-g3hv-75wg-m249. Remove it only when an unforced
resolution passes "aube audit". DocSearch packages use their upstream ranges.
PostCSS and TypeScript are not direct dependencies of this documentation package;
they may still be installed as transitive or peer dependencies.

## Platform Guides

Depending on your host operating system, follow the specific setup instructions below:

| Environment       | Description                                                                                                                      | Link                          |
| :---------------- | :------------------------------------------------------------------------------------------------------------------------------- | :---------------------------- |
| **Mutable Linux** | Instructions for setting up the Nix package manager and virtualization tools on a standard Linux distribution (like Arch Linux). | [View Guide](./mutable_linux) |
| **WSL2**          | The recommended path for Windows users. We use **openSUSE Tumbleweed** inside WSL2 as the host for Nix.                          | [View Guide](./wsl)           |
