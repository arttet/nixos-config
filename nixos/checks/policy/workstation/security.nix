{ workstation, vm, ... }:
[
  {
    assertion = workstation.platform.security.enable;
    message = "workstation must enable platform security";
  }
  {
    assertion = !vm.platform.security.enable;
    message = "vm must keep workstation security disabled";
  }
  {
    assertion = !workstation.security.sudo.enable;
    message = "workstation must disable sudo";
  }
  {
    assertion = workstation.security.doas.enable;
    message = "workstation must enable doas";
  }
  {
    assertion = builtins.any (
      rule:
      rule.groups == [ "wheel" ] && rule.noPass == false && rule.persist == false && rule.keepEnv == false
    ) workstation.security.doas.extraRules;
    message = "workstation doas rules must include minimal wheel-only password-required rule";
  }
  {
    assertion = workstation.security.protectKernelImage;
    message = "workstation must protect kernel image";
  }
  {
    assertion = workstation.security.forcePageTableIsolation;
    message = "workstation must force page table isolation";
  }
  {
    assertion = workstation.boot.tmp.useTmpfs;
    message = "workstation /tmp must use tmpfs";
  }
  {
    assertion = workstation.boot.tmp.cleanOnBoot;
    message = "workstation /tmp must be cleaned on boot";
  }
  {
    assertion = workstation.platform.security.disableThunderbolt;
    message = "workstation must disable Thunderbolt by default";
  }
  {
    assertion = builtins.elem "thunderbolt" workstation.boot.blacklistedKernelModules;
    message = "workstation must blacklist Thunderbolt by default";
  }
  {
    assertion = workstation.services.journald.storage == "persistent";
    message = "workstation journald storage must be persistent";
  }
  {
    assertion = !workstation.services.fail2ban.enable;
    message = "workstation must keep fail2ban disabled when ssh is off";
  }
  {
    assertion = workstation.services.fail2ban.maxretry == 5;
    message = "workstation fail2ban maxretry must be 5";
  }
  {
    assertion = workstation.services.fail2ban.daemonSettings.DEFAULT.findtime == "10m";
    message = "workstation fail2ban daemonSettings must set findtime to 10m";
  }
  {
    assertion = workstation.services.fail2ban.bantime == "1h";
    message = "workstation fail2ban bantime must be 1h";
  }
  {
    assertion = workstation.services.fail2ban.bantime-increment.enable;
    message = "workstation fail2ban must enable bantime-increment";
  }
  {
    assertion = !vm.services.fail2ban.enable;
    message = "vm must keep fail2ban disabled";
  }
  {
    assertion = workstation.boot.kernel.sysctl."kernel.perf_event_paranoid" == 3;
    message = "workstation perf_event_paranoid must be 3";
  }
  {
    assertion = workstation.boot.kernel.sysctl."user.max_user_namespaces" == 0;
    message = "workstation user namespaces must be disabled by upstream sysctl";
  }
]
