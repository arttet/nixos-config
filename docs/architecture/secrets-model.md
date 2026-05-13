# Secrets Model

Secrets and identity stay outside git.

The repository may define where private material enters the system, but it must
not contain real usernames, SSH keys, API tokens, VPN credentials, hardware
configuration, generated machine identity, or encrypted secrets.

Milestone 001 uses local overlays as the boundary for private user state.
