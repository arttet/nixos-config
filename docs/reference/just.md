# Just

`just` is the command surface for the repository.

The root `justfile` imports modules from `misc/justfiles/`, so commands can be
grouped by domain:

```sh
just guest build
just guest run
just guest daemon
just guest status
just guest ssh
just guest stop
just guest test
just guest clean
just docs build
```
