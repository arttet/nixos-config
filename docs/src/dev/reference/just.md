# Just

`just` is the command surface for the repository.

The root `justfile` imports modules from `misc/justfiles/`, so commands can be
grouped by domain:

```sh
$ just help
Available recipes:
    default # Show help
    help    # List all commands

    [Development]
    fmt           # Format code
    check         # Run repository checks
    build profile # Build a NixOS profile closure
    test profile  # Run script tests and selected profile checks
    switch profile # Switch the installed NixOS system to a profile

    [VM Runtime]
    vm:
        build    # Build the VM
        run      # Run the VM
        daemon   # Start the VM in the background
        status   # Show VM status
        ssh      # Open an SSH session into the VM
        stop     # Stop the background VM
        test     # Validate daemon startup, SSH reachability, and VM network
        validate # Validate the VM profile without starting QEMU
        clean    # Remove VM state

    [Workstation]
    workstation:
        build          # Build the workstation system closure
        test           # Validate the workstation profile
        runtime-checks # Print real-hardware workstation tuning validation commands
        dns-report     # Print real-hardware workstation DNS validation commands
        network-report # Print real-hardware workstation network validation commands
        logs-report    # Print real-hardware workstation log validation commands

    [Desktop]
    desktop:
        build        # Build the desktop system closure
        test         # Validate the desktop profile
        power-checks # Print real-hardware desktop power validation commands

    [Homelab Raspberry Pi]
    homelab:
        check            # Validate local state, target evaluation, and policy
        image            # Build the Raspberry Pi 5 microSD image
        flash device     # Safely flash the image to a whole block device
        deploy [mode]         # Activate on NIXOS_TARGET_HOST; defaults to test
        deploy-to host [mode] # Activate on an explicit server
        storage-unlock        # Unlock the existing LUKS SSD and start storage services
        status                # Show compact health and service state over one SSH connection
        benchmark-network     # Run direct and reverse iperf3 throughput tests

    [Local Overlay]
    overlay:
        path  # Print the local user overlay path
        check # Check that the local user overlay exists

    [Documentation]
    docs:
        dev     # Serve docs
        build   # Build docs
        preview # Preview docs
```

The root profile commands default to the flake `default` target:

```sh
just build
just test
just switch
```

Pass a profile when you want a specific target:

```sh
just build desktop
just test desktop
just switch desktop
```

`just fmt` runs `dprint fmt`, `just --fmt`, and `nix fmt`.
