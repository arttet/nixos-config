const image_link = "target/homelab-rpi5-image"

def mounted-paths [device: record] {
  let own = ($device.mountpoints? | default [] | where {|mount| $mount != null and $mount != "" })
  let children = ($device.children? | default [])
  $own ++ ($children | each {|child| mounted-paths $child } | flatten)
}

def validate-device-metadata [device_path: string, metadata: record] {
  if ($device_path !~ '^/dev/(sd[a-z]+|mmcblk[0-9]+)$') {
    error make { msg: "Destination must be a whole /dev/sdX or /dev/mmcblkN device, never a partition." }
  }
  let devices = ($metadata.blockdevices? | default [])
  let selected = ($devices | where {|device| ($device.path? | default "") == $device_path })
  if ($selected | length) != 1 {
    error make { msg: $"lsblk did not return exactly one whole device for ($device_path)." }
  }
  let device = ($selected | first)
  if ($device.type? | default "") != "disk" {
    error make { msg: $"Destination is not a whole disk: ($device_path)" }
  }
  let size = ($device.size? | default 0 | into int)
  if $size <= 0 {
    error make { msg: $"Refusing to flash a zero-size device: ($device_path). Reinsert the card and verify the reader with lsblk." }
  }
  let mounts = (mounted-paths $device)
  if not ($mounts | is-empty) {
    error make { msg: $"Refusing to flash a device with mounted filesystems: ($mounts | str join ', ')" }
  }
  $device
}

def flash-device [device_path: string, --dry-run, --metadata-file: path] {
  let metadata = if $dry_run {
    if $metadata_file == null { error make { msg: "--dry-run requires --metadata-file with lsblk JSON." } }
    open $metadata_file
  } else {
    if not ($device_path | path exists) { error make { msg: $"Block device does not exist: ($device_path)" } }
    let result = (^lsblk --json --bytes -o NAME,PATH,SIZE,MODEL,TRAN,TYPE,MOUNTPOINTS $device_path | complete)
    if $result.exit_code != 0 { error make { msg: $"lsblk failed: ($result.stderr)" } }
    $result.stdout | from json
  }
  let selected = (validate-device-metadata $device_path $metadata)
  print ($selected | select path size model tran type mountpoints | table)
  if $dry_run {
    print "Dry-run validation passed; no data was written."
    return
  }

  let images = (glob $"($image_link)/sd-image/*.img.zst")
  if ($images | length) != 1 {
    error make { msg: $"Expected exactly one .img.zst under ($image_link)/sd-image; run `just homelab image` first." }
  }
  print "WARNING: all data on the selected device will be destroyed."
  let confirmation = (input $"Type the complete device path to continue [($device_path)]: ")
  if $confirmation != $device_path { error make { msg: "Confirmation did not match; nothing was written." } }
  let image = ($images | first)
  ^zstd -dc $image | ^doas dd $"of=($device_path)" bs=4M status=progress conv=fsync
  ^sync
  print $"Flash completed and buffers were synchronized. It is safe to remove ($device_path)."
}

def main [
  action: string
  argument?: string
  --dry-run
  --metadata-file: path
] {
  match $action {
    "flash" => {
      if $argument == null { error make { msg: "flash requires a whole block device." } }
      flash-device $argument --dry-run=$dry_run --metadata-file=$metadata_file
    }
    _ => { error make { msg: "Expected action: flash. Other homelab workflows are direct just recipes." } }
  }
}
