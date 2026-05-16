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

If `systemd-resolved` is failing, check its logs:

```sh
journalctl -u systemd-resolved -e
```

## 🧱 Firewall Rules

The system uses `nftables` under the hood for the firewall. To view the active ruleset (requires `doas`):

```sh
doas nft list ruleset
```

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
