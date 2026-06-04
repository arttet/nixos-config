-- Hyprland greeter compositor config for regreet.
-- Deployed to /etc/greetd/hyprland-greeter.lua by greetd.nix.
-- All binaries and share paths use /run/current-system/sw/ so this file
-- requires no Nix substitutions and can be edited directly.

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

hl.env("GDK_BACKEND", "wayland")
hl.env("GTK_USE_PORTAL", "0")
hl.env("GDK_DEBUG", "no-portals")
hl.env("GTK_MEDIA", "none")
hl.env("HOME", "/var/lib/regreet")
hl.env("XDG_CACHE_HOME", "/var/cache/regreet")
hl.env("XDG_CONFIG_HOME", "/var/lib/regreet/config")
hl.env("XDG_STATE_HOME", "/var/lib/regreet")

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP")
    hl.exec_cmd(
        "/run/current-system/sw/bin/regreet"
        .. "; /run/current-system/sw/bin/hyprctl dispatch exit"
    )
end)

hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_hyprland_guiutils_check = true,
    },
})
