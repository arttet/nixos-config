# Rebuilding

Rebuild the VM whenever infrastructure changes:

```sh
just vm build
```

Boot it again to validate runtime behavior:

```sh
just vm run
```

For background operation:

```sh
just vm daemon
just vm status
just vm stop
```
