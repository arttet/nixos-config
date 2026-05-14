# Just

`just` is the command surface for the repository.

The root `justfile` imports modules from `misc/justfiles/`, so commands can be
grouped by domain:

```sh
just vm build
just vm run
just vm daemon
just vm status
just vm ssh
just vm stop
just vm test
just vm clean
just workstation build
just workstation test
just docs build
```
