# Disk Encryption

Disk encryption is planned, documented, and prepared for, but it is not enabled
as the default workstation runtime path yet.

The first supported encrypted root model should be passphrase-based unlock from
the boot console. This keeps the initial install path understandable and avoids
depending on hardware token or firmware-specific behavior during the first real
workstation milestone.

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

The current repository does not require encryption to build or run `workstation`
or `vm`.
