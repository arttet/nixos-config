# Rebuilding

Rebuild the guest VM whenever infrastructure changes:

```sh
just guest build
```

Boot it again to validate runtime behavior:

```sh
just guest run
```

For background operation:

```sh
just guest daemon
just guest status
just guest stop
```
