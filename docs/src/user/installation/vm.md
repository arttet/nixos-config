# 🖥️ VM

The `vm` profile gives you a safe, disposable sandbox. It is a local QEMU virtual machine that mirrors your workstation's underlying configuration.

Before applying a risky configuration change to your actual physical computer, you can build and boot it here to ensure it works. **If you break the VM, you can just delete it and start over.**

## 🔨 1. Building the VM

To compile the virtual machine from your current NixOS configuration:

```sh
just vm build
```

This creates an executable VM runner, placing it in the `target/` directory (which is ignored by Git).

## 🚀 2. Running the VM

You have two ways to run the VM depending on your workflow.

#### Option A: Interactive (Foreground)

If you want to see the boot process and log into the console directly:

```sh
just vm run
```

- QEMU will start in your terminal.
- Wait for the console login prompt.
- **Username:** `user`
- **Password:** `user`

To gracefully shut down from inside the VM, type `sudo poweroff`.
If the VM hangs and you need to force-quit from your terminal, press `Ctrl+A`, let go, and then press `x`.

#### Option B: Background Daemon (Headless)

If you want the VM to run quietly in the background so you can SSH into it (the preferred workflow for testing network services or running automated checks):

```sh
just vm daemon
```

To see if your background VM is running and which ports are mapped:

```sh
just vm status
```

To easily open an SSH session into the running daemon:

```sh
just vm ssh
```

_(When prompted for a password, type `user`)_

## 🧪 3. Running Automated Tests

To ensure the VM boots, SSH is accessible, and the VM can reach the internet, you can run the automated test suite:

```sh
just vm test
```

_(Note: This uses `sshpass` under the hood. If your host machine doesn't have it installed, the test might fail)._

## 🧹 4. Cleaning Up

Since the VM is meant to be disposable, you should clean it up when you are done. This deletes the virtual hard drive and any temporary states without touching your actual Nix configurations:

```sh
just vm stop
just vm clean
```

You now have a clean slate for your next experiment!
