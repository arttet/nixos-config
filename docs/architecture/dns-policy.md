# DNS Policy

The workstation uses an explicit DNS policy through `systemd-resolved`.

```nix
services.resolved = {
  enable = true;
  dnssec = "true";
  dnsovertls = "true";
  domains = [ "~." ];
  fallbackDns = [
    "1.1.1.1#cloudflare-dns.com"
    "1.0.0.1#cloudflare-dns.com"
  ];
};
```

NetworkManager is configured to hand DNS resolution to `systemd-resolved`.

## Rationale

- Resolver behavior is explicit.
- DNS does not silently depend on ISP defaults.
- Cloudflare DNS is the default baseline.
- DNS-over-TLS is preferred where practical.
- Google DNS is not the preferred default; it may be considered later only as a
  deliberate fallback.

The VM does not force this workstation DNS policy. QEMU user networking should
remain simple and disposable.

## Validation

Run on installed workstation hardware:

```sh
resolvectl status
resolvectl query example.com
```

If DNS-over-TLS causes a local network problem, use a host-specific override or
local overlay and document the reason.
