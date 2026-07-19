{ config, lib, ... }:
let
  cfg = config.platform.homelab;
in
{
  config = lib.mkIf (cfg.enable && cfg.services.mailpit) {
    users.groups.mailpit = { };
    users.users.mailpit = {
      isSystemUser = true;
      group = "mailpit";
      home = "/srv/data/mailpit";
      createHome = false;
    };

    services.mailpit.instances.homelab = {
      listen = "127.0.0.1:8025";
      smtp = "127.0.0.1:1025";
      database = "mailpit.db";
      # "ui-auth-file" is passed straight through as a CLI flag (freeform
      # passthrough, not a systemd EnvironmentFile=), so cfg.mailpit.environmentFile
      # here must point at a htpasswd-format bcrypt credentials file, NOT a
      # KEY=VALUE env file like every other secret in this repo. Exact format
      # unconfirmed against the pinned mailpit version — verify on first deploy.
      ui-auth-file = cfg.mailpit.environmentFile;
    };

    systemd.services.mailpit-homelab = {
      # Replaces the upstream module's default ["multi-user.target"]: the
      # message database lives on the encrypted /srv volume, which isn't
      # mounted until homelab-storage.target fires.
      wantedBy = lib.mkForce [ "homelab-storage.target" ];
      after = [ "homelab-storage.target" ];
      requires = [ "homelab-storage.target" ];
      unitConfig.ConditionPathExists = cfg.mailpit.environmentFile;
      serviceConfig = {
        # DynamicUser is unconditional upstream (no static-user escape hatch
        # in this module at all); pin the static user defined above instead,
        # matching every other native homelab service.
        DynamicUser = lib.mkForce false;
        User = "mailpit";
        Group = "mailpit";
        # WorkingDirectory defaults to "%S/mailpit" (StateDirectory
        # expansion); forcing StateDirectory off means %S no longer exists,
        # so this must become an absolute /srv path instead. The relative
        # "mailpit.db" database setting above resolves against it.
        WorkingDirectory = lib.mkForce "/srv/data/mailpit";
        StateDirectory = lib.mkForce [ ];
      };
    };
  };
}
