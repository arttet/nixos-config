# ✨ Nix Style & Best Practices

To maintain a high-quality, professional codebase, we follow a set of strict engineering standards when writing Nix code. These guidelines ensure that the configuration is predictable, searchable, and easy for other developers to understand.

## 🏷️ Naming Conventions

### Option Names

Use camelCase for all custom options. Choose names that describe the _capability_ or _policy_, not just the package name.

- ✅ `platform.security.hardenedKernel.enable`
- ❌ `platform.enable_linux_hardened`

### File Naming

- Use `default.nix` for directory entry points (the main module/profile).
- Use kebab-case for specific module files: `boot-ux.nix`, `local-overlay.nix`.

## 🛠️ Logic and Structure

### 1. Explicit Over Implicit

We avoid complex logic that hides how the system is built. If a module depends on another, it should ideally be imported explicitly or checked via `config` options.

### 2. Use of `mkIf` and `mkMerge`

Always wrap your module implementation in `mkIf` based on an `enable` option. This allows the module to be safely imported without automatically activating its logic.

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.platform.feature;
in {
  options.platform.feature.enable = lib.mkEnableOption "Description of feature";

  config = lib.mkIf cfg.enable {
    # implementation here
  };
}
```

### 3. Clean Imports

Group imports logically. Always prefer relative paths (`./module.nix`) over complex absolute lookups unless referring to a global profile.

## 🛡️ Best Practices

### Avoid "Nix Magic"

- Do not use `builtins.readDir` to automatically import every file in a folder. It makes the code hard to grep and breaks the "explicit is better than implicit" rule.
- Do not use `with pkgs;` at the top of files. It pollutes the namespace and makes it unclear where a package is coming from. Instead, use explicit references like `pkgs.git`.

### Unfree Packages

Unfree software is only permitted in the graphical workstation product. Use the provided platform options to enable unfree packages globally or per-package to maintain an audit trail.

### External Flake Inputs

Pin every external input in `flake.nix`. Avoid using `nix-channel` or unpinned URLs. This ensures that a build today will produce the exact same result a year from now.
