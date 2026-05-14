# Disk Encryption

Disk encryption is enabled for the workstation storage layout.

The supported model is LUKS2 with manual passphrase unlock from the boot
console. This keeps the first encrypted install path understandable and avoids
depending on hardware token or firmware-specific behavior.

Future extensions may add:

- YubiKey-assisted unlock.
- TPM-backed unlock.
- Recovery-key handling.
- More automated enrollment flows.

Secure Boot is not supported yet. Do not assume Secure Boot validation or key
enrollment exists until it is explicitly implemented and documented.

## Install Boundary

Encryption setup is a destructive storage operation. A real install must happen
only after reviewing the target disk device and confirming that all data on that
device can be erased.

The current repository does not require TPM, YubiKey, or Secure Boot to build,
run, or install `workstation`.
