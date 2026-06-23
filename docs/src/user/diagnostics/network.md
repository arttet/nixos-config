# 🌐 Networking Diagnostics

If you have no internet access or are experiencing slow connections, use these commands to diagnose the network stack.

## 🔌 Verifying Network Interfaces

First, ensure your network interfaces are recognized and have IP addresses assigned.

```sh
ip a
```

To check the status of devices managed by NetworkManager:

```sh
nmcli device status
```

**Expected result:** You should see your Ethernet (`enp*`) or Wi-Fi (`wlan*`) interface listed as `connected`.

## 📡 Testing Connectivity

Test basic connectivity by pinging an external IP address (bypassing DNS):

```sh
ping -c 4 1.1.1.1
```

If this succeeds but websites don't load, you have a DNS issue.

## 📇 Diagnosing DNS (systemd-resolved)

The platform explicitly routes DNS through `systemd-resolved` using Cloudflare DNS over TLS.

To check the current status and upstream servers:

```sh
resolvectl status
```

To manually query a domain and see which server responded:

```sh
resolvectl query example.com
```

The workstation also includes traditional and modern DNS clients:

```sh
nslookup example.com
dig example.com
q example.com
```

If `systemd-resolved` is failing, check its logs:

```sh
journalctl -u systemd-resolved -e
```

## Route, HTTP, and TLS Diagnostics

Trace the network route to a host:

```sh
traceroute example.com
```

Inspect an HTTP response without downloading its body:

```sh
curl --head https://example.com
```

Inspect the remote TLS certificate and handshake:

```sh
openssl s_client -connect example.com:443 -servername example.com
```

Use `jq` when an HTTP endpoint returns JSON:

```sh
curl --silent https://api.github.com | jq .
```

## VPN and Tor Clients

The workstation includes OpenVPN, WireGuard, and Tor command-line clients:

```sh
openvpn --version
wg --version
wg-quick --help
tor --version
```

No VPN or Tor profile, interface, system service, firewall exception, or secret
is configured by the repository. Keep configuration and credentials outside
the repository and start a client explicitly when needed. The WireGuard kernel
module is provided by the kernel and loads on demand.

## 🧱 Firewall Rules

The desktop keeps the NixOS firewall enabled and adds OpenSnitch for per-process
outbound connection rules. OpenSnitch uses its native `nftables` backend and
starts its UI service in the background with the graphical session. The main
window stays hidden until opened manually, while permission dialogs appear for
unknown connections. Existing rules continue to work without the UI; if the UI
is unavailable, unknown connections use the permissive `allow` fallback.

```sh
systemctl status opensnitchd
journalctl -u opensnitchd
doas nft list ruleset
opensnitch-ui
```

Rules created through the GUI are local runtime state under
`/var/lib/opensnitch/rules`.

## ⚙️ Runtime Network Tuning Checks

The workstation profile applies specific TCP tuning (`bbr`, `fq`, and fastopen). To verify these are active:

```sh
sysctl net.ipv4.tcp_congestion_control
```

```sh
sysctl net.core.default_qdisc
```

```sh
sysctl net.ipv4.tcp_fastopen
```
