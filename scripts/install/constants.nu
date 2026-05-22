export def default-state [] {
  {
    session: "system"
    profile: "default"
    user_description: "User"
    user: "user"
    password: ""
    password_hash: ""
    hostname: "pc"
    timezone: "UTC"
    disk: ""
    action: "dry-run"
  }
}

export def allowed-profiles [] {
  [ "default" "workstation" "desktop" ]
}

export def disko-mode [] {
  "destroy,format,mount"
}

export def platform-state-schema [] {
  "platform-state.v1.schema.json"
}

export def disko-state-schema [] {
  "disko-state.v1.schema.json"
}

export def ui-width [] {
  let size = (try { term size } catch { { columns: 80 } })
  let columns = ($size.columns? | default 80)

  if $columns < 72 {
    $columns
  } else {
    $columns - 2
  }
}

export def kv-label-width [] {
  18
}
