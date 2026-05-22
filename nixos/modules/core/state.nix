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
      defaultDotfileLinks = [
        ".config/alacritty"
        ".config/bash"
        ".config/fastfetch"
        ".config/git"
        ".config/lazygit"
        ".config/nushell"
        ".config/nvim"
        ".config/shell"
        ".config/starship"
        ".config/tmux"
        ".config/wezterm"
        ".config/yazi"
        ".config/zsh"
        ".zshrc"
      ];
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
            links = if sources == null then [ ] else sources.links or defaultDotfileLinks;
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
          dotfileLinks = userSources.links or defaultDotfileLinks;
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
              linkFile =
                target:
                {
                  source = link (dotfilesRoot + "/${target}");
                }
                // lib.optionalAttrs (target == ".config/nushell") {
                  force = true;
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
