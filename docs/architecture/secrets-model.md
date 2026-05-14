# Secrets Model

Secrets and identity stay outside git.

The repository may define where private material enters the system, but it must
not contain real usernames, SSH keys, API tokens, VPN credentials, hardware
configuration, generated machine identity, or encrypted secrets.

Local overlays are the boundary for private user and host state. The committed
overlay example in `examples/local/user.nix` intentionally avoids real names,
SSH keys, and secrets.
