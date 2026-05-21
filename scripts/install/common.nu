export def normalize-path [] {
  $in | path expand | split row '\' | str join '/'
}

export def join-path [parts: list<string>] {
  $parts | path join | split row '\' | str join '/'
}

export def repo-root [] {
  $env.FILE_PWD | path dirname | path dirname | normalize-path
}

export def temp-root [] {
  $env.NIX_CONFIG_INSTALL_TMP? | default "/run/nixos-config-installer/runtime"
}

export def schema-path [name: string] {
  join-path [ (repo-root) "schemas" $name ]
}

export def validate-disk [disk_device: string] {
  if ($disk_device | str trim) == "" {
    error make { msg: "disk device is required" }
  }

  if not ($disk_device | str starts-with "/dev/") {
    error make { msg: "disk device must be an absolute /dev path" }
  }

  if not ($disk_device =~ '^/dev/[A-Za-z0-9/._-]+$') {
    error make { msg: "disk device must be a valid absolute /dev path without special characters" }
  }
}

export def ensure-dir [dir: string] {
  mkdir $dir

  if not ($dir | path exists) {
    error make { msg: $"failed to create directory: ($dir)" }
  }
}

export def validate-json [schema: string, data: string] {
  require-json-schema-tool

  let result = (check-jsonschema --schemafile $schema $data | complete)
  if $result.exit_code != 0 {
    let stderr = ($result.stderr | str trim)
    let stdout = ($result.stdout | str trim)
    let detail = if $stderr != "" { $stderr } else { $stdout }
    error make { msg: $"JSON contract validation failed for ($data): ($detail)" }
  }
}

export def write-json-contract [schema: string, path: string, value: record] {
  ensure-dir ($path | path dirname)
  $value | to json --indent 2 | save --force $path
  validate-json $schema $path
}

export def require-json-schema-tool [] {
  if (which check-jsonschema | length) == 0 {
    error make { msg: "check-jsonschema is required to validate installer JSON contracts" }
  }
}
