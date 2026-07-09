{ lib }:
let
  # Absolute paths are taken verbatim; relative paths anchor under the flake root.
  resolvePath = root: path: if lib.hasPrefix "/" path then /. + path else root + "/${path}";
in
{
  # `required` paths come from explicit env vars and are returned unchecked so the consuming
  # module (nixos/modules/core/local.nix) can assert their existence with a clear message.
  # Auto-discovered paths must degrade to null under pure eval when missing, so their existence
  # is probed defensively via tryEval.
  localPathOrNull =
    root: path: required:
    if path == "" then
      null
    else
      let
        resolved = resolvePath root path;
      in
      if required then
        resolved
      else
        let
          check = builtins.tryEval (builtins.pathExists resolved);
        in
        if check.success && check.value then resolved else null;
}
