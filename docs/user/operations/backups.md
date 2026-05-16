# 💾 Backups

Use this page for manual backups from an installed workstation.

The operating system is reproducible from the repository. The important backup
targets are personal data, local machine identity, and secrets.

## 📦 What to Back Up

Back up these categories:

| Category | Why it matters | Example paths |
| --- | --- | --- |
| Documents | Personal files | `~/Documents`, `~/Desktop`, selected media folders |
| Local identity | Hostname, timezone, local user, password hash, private host settings | `/root/.nix-config-local/user.nix`, `/root/.nix-config-local/user.passwd` |
| Secrets | Private credentials and key material | selected SSH, GPG, password manager, or token files |
| App state | Only when intentionally needed | selected browser, editor, or profile data |
| LUKS2 Header | Vital if the primary header is corrupted | Explicitly collected file (see below) |

Do not upload local identity files, secrets, or LUKS headers to remote storage
unless the backup is encrypted.

## 📁 Create a Backup Workspace

Create a timestamped local workspace:

```sh
backup_dir="$HOME/workstation-backup-$(date +%Y%m%d-%H%M%S)"
```

```sh
mkdir -p "$backup_dir"
```

## 🔐 Back Up Local Identity

The installer stores machine-local identity under root. Copy the overlay and
password hash file into the backup workspace:

```sh
doas cp /root/.nix-config-local/user.nix "$backup_dir/user.nix"
```

```sh
doas cp /root/.nix-config-local/user.passwd "$backup_dir/user.passwd"
```

```sh
doas chown "$USER:$(id -gn)" "$backup_dir/user.nix" "$backup_dir/user.passwd"
```

```sh
chmod 600 "$backup_dir/user.nix" "$backup_dir/user.passwd"
```

`user.passwd` contains the hashed login password. Treat it as sensitive
material.

## 🛡️ Back Up the LUKS2 Header

If the LUKS header on your encrypted drive becomes corrupted, you will lose access to all data, even if you know the password. Backing it up is critical.

Identify your LUKS container partition (e.g., `/dev/nvme0n1p3` or `/dev/sda3`):

```sh
lsblk
```

Run the backup command (replace `<partition>` with your actual encrypted partition, not the mapped `/dev/mapper/...` device):

```sh
doas cryptsetup luksHeaderBackup /dev/<partition> --header-backup-file "$backup_dir/luks-header-backup.img"
```

**WARNING:** The header file contains your encryption keys. Treat it exactly like an unencrypted private key.

## 🗂️ Back Up Selected User Data

Copy only directories you intentionally want to keep. Example:

```sh
mkdir -p "$backup_dir/home"
```

```sh
rsync -a --info=progress2 "$HOME/Documents/" "$backup_dir/home/Documents/"
```

## 🤐 Create and Encrypt an Archive

Create a compressed archive:

```sh
tar -C "$HOME" -caf "$backup_dir.tar.zst" "$(basename "$backup_dir")"
```

Encrypt the archive before remote storage:

```sh
gpg --symmetric --cipher-algo AES256 "$backup_dir.tar.zst"
```

The `"$backup_dir.tar.zst.gpg"` file can now be stored remotely. Remember to safely delete the unencrypted `$backup_dir` and the `.tar.zst` file.
