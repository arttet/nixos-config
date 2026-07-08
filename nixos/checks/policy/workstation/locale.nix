{ workstation, ... }:
[
  {
    assertion = workstation.i18n.defaultLocale == "en_US.UTF-8";
    message = "workstation locale must be en_US.UTF-8";
  }
  {
    assertion = workstation.console.keyMap == "us";
    message = "workstation console keymap must be us";
  }
  {
    assertion = workstation.console.font == "ter-v18n";
    message = "workstation console font must use Terminus 18";
  }
]
