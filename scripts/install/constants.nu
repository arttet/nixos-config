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
  [ "default" "workstation" "workstation-gui" ]
}

export def disko-mode [] {
  "destroy,format,mount"
}

export def ui-width [] {
  55
}

export def kv-label-width [] {
  16
}
