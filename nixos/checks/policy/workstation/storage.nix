{ workstation, workstationStorageLayout, ... }:
[
  {
    assertion = !workstation.platform.storage.enable;
    message = "workstation storage layout must stay opt-in";
  }
  {
    assertion = workstation.platform.storage.swapFilePath == "/swap/swapfile";
    message = "unexpected workstation swapfile path";
  }
  {
    assertion = workstation.platform.storage.swapSizeMiB == 8192;
    message = "unexpected workstation swapfile size";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.device == "/dev/disk/by-id/workstation-example";
    message = "workstation storage example disk path must be stable";
  }
  {
    assertion = workstationStorageLayout.disk.workstation.content.type == "gpt";
    message = "workstation storage layout must use GPT";
  }
  {
    assertion = workstationStorageLayout.disk.workstation.content.partitions.ESP.size == "512M";
    message = "workstation ESP size must be 512M";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.ESP.content.mountpoint == "/boot/efi";
    message = "workstation ESP mountpoint must be /boot/efi";
  }
  {
    assertion = workstationStorageLayout.disk.workstation.content.partitions.boot.size == "512M";
    message = "workstation boot partition size must be 512M";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.boot.content.mountpoint == "/boot";
    message = "workstation boot mountpoint must be /boot";
  }
  {
    assertion = workstationStorageLayout.disk.workstation.content.partitions.luks.size == "100%";
    message = "workstation LUKS partition must fill remaining disk";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.type == "luks";
    message = "workstation encrypted partition must use luks";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.name == "cryptroot";
    message = "workstation encrypted partition must be named cryptroot";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.extraFormatArgs == [
        "--type"
        "luks2"
      ];
    message = "workstation encrypted partition must use LUKS2";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.content.type == "btrfs";
    message = "workstation encrypted filesystem must be btrfs";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.content.subvolumes."@root".mountpoint
      == "/";
    message = "workstation root subvolume must mount at /";
  }
  {
    assertion =
      workstationStorageLayout.disk.workstation.content.partitions.luks.content.content.subvolumes."@swap".mountpoint
      == "/swap";
    message = "workstation swap subvolume must mount at /swap";
  }
]
