let
  statePath = builtins.getEnv "NIX_CONFIG_DISKO_STATE";
  state =
    if statePath == "" then
      throw "NIX_CONFIG_DISKO_STATE must point to disko-state.json"
    else
      builtins.fromJSON (builtins.readFile statePath);
in
{
  disko.devices = import ../../nixos/modules/storage/layout.nix {
    diskDevice = state.disk.device;
    luksPasswordFile = state.luks.passwordFile or null;
  };
}
