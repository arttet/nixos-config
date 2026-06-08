{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.platform.state = {
    enable = lib.mkEnableOption "platform state JSON application";

    file = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to the validated platform state JSON contract.";
    };
  };

  config =
    let
      cfg = config.platform.state;
      stateFileExists = cfg.file != null && builtins.pathExists cfg.file;
      state = if stateFileExists then builtins.fromJSON (builtins.readFile cfg.file) else { };
      host = state.host or { };
      stateUsers = state.users or [ ];
      defaultHomeStateVersion = config.system.stateVersion;
      userNames = map (user: user.name or "") stateUsers;
      userPasswordFiles = map (user: user.hashedPasswordFile or "") stateUsers;
      shells = {
        bash = pkgs.bashInteractive;
        inherit (pkgs) nushell zsh;
      };
      userShellNames = map (user: user.shell or "nushell") stateUsers;
      userSourcesFor = user: user.sources or null;
      isValidDotfileLink =
        link:
        (builtins.isString link) && link != "" && !(lib.hasPrefix "/" link) && !(lib.hasInfix ".." link);
      userLinkAssertions = lib.flatten (
        map (
          user:
          let
            userName = user.name or "<unknown>";
            sources = userSourcesFor user;
            links = if sources == null then [ ] else sources.links or [ ];
          in
          lib.optional (sources != null) {
            assertion = builtins.all isValidDotfileLink links;
            message = "platform state users[].sources.links for ${userName} must contain relative dotfile paths without '..'.";
          }
          ++ lib.optional (sources != null) {
            assertion = (lib.length links) == (lib.length (lib.unique links));
            message = "platform state users[].sources.links for ${userName} must be unique.";
          }
          ++ lib.optional (sources != null && links != [ ]) {
            assertion = (sources.dotfilesRoot or null) != null;
            message = "platform state users[].sources.dotfilesRoot for ${userName} is required when links are configured.";
          }
        ) stateUsers
      );
      loadGitSigningKey = pkgs.writeTextFile {
        name = "load-git-signing-key";
        executable = true;
        text = ''
          #!${pkgs.nushell}/bin/nu

          let configured_key = (^${pkgs.git}/bin/git config --global --path user.signingKey | complete)
          if $configured_key.exit_code != 0 {
            exit 0
          }

          let public_key = ($configured_key.stdout | str trim)
          if ($public_key | is-empty) {
            exit 0
          }

          let private_key = ($public_key | str replace --regex '\.pub$' "")
          if ($private_key | path exists) {
            ^${pkgs.openssh}/bin/ssh-add $private_key
          }
        '';
      };
      mkUser =
        user:
        let
          userName = user.name;
          shellName = user.shell or "nushell";
          isAdmin = user.isAdmin or false;
          extraGroups = lib.unique ((user.extraGroups or [ ]) ++ lib.optional isAdmin "wheel");
        in
        {
          name = userName;
          value = {
            isNormalUser = true;
            inherit (user) description;
            shell = shells.${shellName} or pkgs.nushell;
            inherit (user) hashedPasswordFile;
            inherit extraGroups;
          };
        };
      usersWithSources = builtins.filter (user: (userSourcesFor user) != null) stateUsers;
      mkHomeUser =
        user:
        let
          userName = user.name;
          userDescription = user.description;
          userHome = "/home/${userName}";
          userSources = userSourcesFor user;
          dotfilesModule = userSources.dotfilesModule or null;
          dotfilesRoot = userSources.dotfilesRoot or null;
          dotfileLinks = userSources.links or [ ];
          hasDotfilesModule = dotfilesModule != null && builtins.pathExists dotfilesModule;
          hasDotfilesRoot = dotfilesRoot != null && builtins.pathExists dotfilesRoot;
          dotfilesModulePath = if hasDotfilesModule then /. + dotfilesModule else null;
        in
        {
          name = userName;
          value =
            { config, ... }:
            let
              link = config.lib.file.mkOutOfStoreSymlink;
              linkFile = target: {
                source = link (dotfilesRoot + "/${target}");
              };
            in
            {
              imports = lib.optional hasDotfilesModule dotfilesModulePath;

              assertions =
                lib.optional (dotfilesRoot != null) {
                  assertion = hasDotfilesRoot;
                  message = "platform.state users[].sources.dotfilesRoot must point to an existing dotfiles directory";
                }
                ++ lib.optional (dotfilesModule != null) {
                  assertion = builtins.pathExists dotfilesModule;
                  message = "platform.state users[].sources.dotfilesModule must point to an existing Nix module";
                };

              _module.args = {
                inherit
                  dotfilesRoot
                  userDescription
                  userHome
                  userName
                  userSources
                  ;
              };

              home.username = userName;
              home.homeDirectory = userHome;
              home.stateVersion = user.homeStateVersion or defaultHomeStateVersion;
              home.enableNixpkgsReleaseCheck = false;

              programs.home-manager.enable = true;

              home.file = lib.mkIf hasDotfilesRoot (
                builtins.listToAttrs (
                  map (target: {
                    name = target;
                    value = linkFile target;
                  }) dotfileLinks
                )
              );

              systemd.user.services.ssh-add-git-signing-key = {
                Unit = {
                  Description = "Load the Git SSH signing key";
                  After = [
                    "graphical-session.target"
                    "ssh-agent.service"
                  ];
                  Requires = [ "ssh-agent.service" ];
                  PartOf = [ "graphical-session.target" ];
                };

                Service = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
                  ExecStart = "${loadGitSigningKey}";
                };

                Install.WantedBy = [ "graphical-session.target" ];
              };
            };
        };
    in
    lib.mkMerge [
      (lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.file != null;
            message = "platform.state.file must point to state.json when enabled.";
          }
          {
            assertion = stateFileExists;
            message = "platform.state.file points to a missing state.json file.";
          }
          {
            assertion = (state.schemaVersion or null) == 1;
            message = "platform state schemaVersion must be 1.";
          }
          {
            assertion = stateUsers != [ ];
            message = "platform state must define at least one user in users[].";
          }
          {
            assertion = (lib.length userNames) == (lib.length (lib.unique userNames));
            message = "platform state users[].name values must be unique.";
          }
          {
            assertion = builtins.all (shellName: builtins.hasAttr shellName shells) userShellNames;
            message = "platform state users[].shell must be one of: ${lib.concatStringsSep ", " (builtins.attrNames shells)}.";
          }
          {
            assertion = builtins.all (path: builtins.isString path && lib.hasPrefix "/" path) userPasswordFiles;
            message = "platform state users[].hashedPasswordFile must be an absolute path.";
          }
        ]
        ++ userLinkAssertions;

        networking.hostName = lib.mkIf (host ? hostname) (lib.mkForce host.hostname);
        time.timeZone = lib.mkIf (host ? timezone) (lib.mkForce host.timezone);

        _module.args = {
          platformState = state;
        };

        users.users = builtins.listToAttrs (map mkUser stateUsers);
      })

      (lib.mkIf (cfg.enable && usersWithSources != [ ]) {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users = builtins.listToAttrs (map mkHomeUser usersWithSources);
      })
    ];
}
