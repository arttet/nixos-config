# Commands

Commands are grouped through `just` modules.

Core checks:

```sh
just check
```

VM:

```sh
just vm build
just vm run
just vm daemon
just vm ssh
just vm status
just vm stop
just vm clean
just vm test
```

Workstation:

```sh
just workstation build
just workstation test
just workstation-gui build
just workstation-gui test
just workstation runtime-checks
just workstation dns-report
just workstation network-report
just workstation logs-report
```

Workstation GUI:

```sh
just workstation-gui build
just workstation-gui test
```

Local overlay:

```sh
just overlay path
just overlay check
```

Documentation:

```sh
just docs dev
just docs build
just docs preview
```
