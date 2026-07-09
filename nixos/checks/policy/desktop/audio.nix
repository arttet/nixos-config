{ desktop, ... }:
[
  {
    assertion = desktop.services.pipewire.enable;
    message = "desktop must enable PipeWire";
  }
  {
    assertion = desktop.services.pipewire.wireplumber.enable;
    message = "desktop must enable WirePlumber";
  }
]
