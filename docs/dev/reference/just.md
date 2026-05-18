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
    setup         # Prepare this checkout for privileged local rebuilds
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

    [Workstation GUI]
    workstation-gui:
        build # Build the graphical workstation system closure
        test  # Validate the graphical workstation profile

    [Local Overlay]
    overlay:
        path  # Print the local user overlay path
        check # Check that the local user overlay exists

    [Documentation]
    docs:
        dev     # Serve docs
        build   # Build docs
        preview # Preview docs

    [Pull Requests]
    pr:
        create      # Create a new Pull Request
        review n="" # Ask Gemini to review the Pull Request
        view n=""   # View comments for the Pull Request

    [Deployment]
    deploy:
        list        # List Cloudflare Pages projects
        create name # Create a Cloudflare Pages project
        delete name # Delete a Cloudflare Pages project
```

The root profile commands default to the flake `default` target:

```sh
just build
just test
just setup
just switch
```

Pass a profile when you want a specific target:

```sh
just build workstation-gui
just test workstation-gui
just switch workstation-gui
```
