{ workstation, packageNames, ... }:
[
  {
    assertion =
      let
        names = packageNames workstation.environment.systemPackages;
      in
      builtins.elem "helix" names
      && builtins.elem "vim" names
      && builtins.elem "btop" names
      && !(builtins.elem "htop" names);
    message = "workstation package baseline must include helix/vim/btop and exclude htop";
  }
]
