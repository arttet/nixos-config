# modules/core/users.nix
_: {
  users.users.void = {
    isNormalUser = false;
    isSystemUser = true;
    group = "nogroup";
    # no shell, no home, no wheel
  };
  # Real user is defined exclusively in host-specific overlay
}
