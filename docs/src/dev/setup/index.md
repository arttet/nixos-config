# 🏗️ Local Environment

To contribute to this platform, you need a local development environment capable of running **Nix** and **QEMU**.

One of the core strengths of this repository is that it is **distro-agnostic**. You do not need to be running NixOS to build, test, or modify the configuration.

## Repository Tools and Documentation

Install [mise](https://mise.jdx.dev/getting-started.html), review `mise.toml`,
then trust this checkout and install its pinned tools:

```sh
mise trust
mise install aube uv node python
mise install
just docs install
just docs build
```

The first installation step supplies the package managers before mise installs
the npm and Python tools that depend on them. Documentation uses aube and Node.js;
Nix and QEMU are needed for system builds and VM testing, respectively.
Python tools use uv and the project-pinned Python interpreter. These settings are independent of personal dotfiles.

Documentation sources live in `docs/src/`; VitePress configuration lives in
`docs/.vitepress/`. A successful build writes `docs/.vitepress/dist/` and rejects
unresolved internal page links. Start `just docs dev` for local editing.

### Updating Tools

```sh
just outdated
just upgrade
mise install
```

`just upgrade` first installs the configured aube, uv, Node.js, and Python versions,
then upgrades these prerequisites and writes their new project pins before
upgrading other tools. It limits upgrades to project configuration and keeps
previous installations. Review the resulting `mise.toml` diff.

If a previous bulk upgrade failed with `requires configured install dependency`,
the newly installed version can differ from the version still selected by the
project. Run `mise install aube uv node python`, then retry `just upgrade`.
Do not remove dependency settings or rely on an unrelated executable from PATH.

### Updating Documentation Dependencies

```sh
just docs update
just docs audit
just docs install
just docs build
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
