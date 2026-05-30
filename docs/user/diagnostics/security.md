# 🛡️ Security & Auditing Diagnostics

This page covers how to inspect system logs for authentication events, failed logins, and administrative actions.

## 🔐 Viewing Authentication Logs

NixOS aggregates authentication logs via systemd's journal. You can view all login attempts (both successful and failed) by querying the `systemd-logind` and SSH services.

To view SSH login attempts:

```sh
journalctl -u sshd
```

_(Note: SSH is disabled by default in the `workstation-gui` profile. If you have explicitly enabled it, you should monitor these logs)._

To view local TTY or graphical login events:

```sh
journalctl -u systemd-logind
```

## 🚨 Auditing Failed Logins

To specifically search the journal for failed authentication attempts across the system:

```sh
journalctl | grep "authentication failure"
```

## 🔑 Privilege Escalation (`doas`) Auditing

The workstation uses `doas` instead of `sudo` for privilege escalation. To see a record of all commands executed with elevated privileges:

```sh
journalctl | grep doas
```

This will show who ran `doas`, when they ran it, and what command they executed.

## 👤 Session History

To see a list of users who have recently logged into the system, including when they logged in and out:

```sh
last
```

To see a list of all users who are currently logged into the system:

```sh
who
```
