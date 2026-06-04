{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "graphite-grub-theme";
  version = "unstable-2024-06-23";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "Graphite-gtk-theme";
    rev = "e320fd7319c8199e48a0febd04838adca8dc4c3e";
    sha256 = "0hvf1z0m96jc0s5gznrcmyls77s807s29pjq02344zbcc4k8gh9z";
  };

  variant = "default";
  resolution = "1080p";
  fontSize = "16";

  installPhase =
    let
      colorSuffix = if finalAttrs.variant == "nord" then "-nord" else "";
      assetsDir = if finalAttrs.variant == "nord" then "assets-nord" else "assets";
    in
    ''
      runHook preInstall

      mkdir -p $out/share/grub/themes/graphite

      # Common files used directly by theme.txt.
      install -Dm444 $src/other/grub2/common/terminal_box_c.png $out/share/grub/themes/graphite/terminal_box_c.png
      install -Dm444 $src/other/grub2/common/terminal_box_e.png $out/share/grub/themes/graphite/terminal_box_e.png
      install -Dm444 $src/other/grub2/common/terminal_box_n.png $out/share/grub/themes/graphite/terminal_box_n.png
      install -Dm444 $src/other/grub2/common/terminal_box_ne.png $out/share/grub/themes/graphite/terminal_box_ne.png
      install -Dm444 $src/other/grub2/common/terminal_box_nw.png $out/share/grub/themes/graphite/terminal_box_nw.png
      install -Dm444 $src/other/grub2/common/terminal_box_s.png $out/share/grub/themes/graphite/terminal_box_s.png
      install -Dm444 $src/other/grub2/common/terminal_box_se.png $out/share/grub/themes/graphite/terminal_box_se.png
      install -Dm444 $src/other/grub2/common/terminal_box_sw.png $out/share/grub/themes/graphite/terminal_box_sw.png
      install -Dm444 $src/other/grub2/common/terminal_box_w.png $out/share/grub/themes/graphite/terminal_box_w.png
      install -Dm444 $src/other/grub2/common/terminus-14.pf2 $out/share/grub/themes/graphite/terminus-14.pf2
      install -Dm444 $src/other/grub2/common/dejavu_sans_${finalAttrs.fontSize}.pf2 $out/share/grub/themes/graphite/dejavu_sans_${finalAttrs.fontSize}.pf2

      # Theme config
      install -Dm444 $src/other/grub2/config/theme-${finalAttrs.resolution}.txt $out/share/grub/themes/graphite/theme.txt

      # Background for GRUB theme
      install -Dm444 $src/other/grub2/backgrounds/${finalAttrs.resolution}/wave-dark${colorSuffix}.png $out/share/grub/themes/graphite/background.png

      # Background for greeter reuse.
      install -Dm444 $src/other/grub2/backgrounds/${finalAttrs.resolution}/wave-dark${colorSuffix}.png $out/share/backgrounds/graphite/nord-dark.png

      # Icons for normal Linux entries, recovery entries, submenus, and fallback.
      install -Dm444 $src/other/grub2/assets/logos${colorSuffix}/${finalAttrs.resolution}/gnu-linux.png $out/share/grub/themes/graphite/icons/gnu-linux.png
      install -Dm444 $src/other/grub2/assets/logos${colorSuffix}/${finalAttrs.resolution}/linux.png $out/share/grub/themes/graphite/icons/linux.png
      install -Dm444 $src/other/grub2/assets/logos${colorSuffix}/${finalAttrs.resolution}/recovery.png $out/share/grub/themes/graphite/icons/recovery.png
      install -Dm444 $src/other/grub2/assets/logos${colorSuffix}/${finalAttrs.resolution}/submenu.png $out/share/grub/themes/graphite/icons/submenu.png
      install -Dm444 $src/other/grub2/assets/logos${colorSuffix}/${finalAttrs.resolution}/unknown.png $out/share/grub/themes/graphite/icons/unknown.png

      # Assets used directly by theme.txt.
      install -Dm444 $src/other/grub2/assets/${assetsDir}/${finalAttrs.resolution}/select_c.png $out/share/grub/themes/graphite/select_c.png
      install -Dm444 $src/other/grub2/assets/${assetsDir}/${finalAttrs.resolution}/select_e.png $out/share/grub/themes/graphite/select_e.png
      install -Dm444 $src/other/grub2/assets/${assetsDir}/${finalAttrs.resolution}/select_w.png $out/share/grub/themes/graphite/select_w.png
      install -Dm444 $src/other/grub2/assets/${assetsDir}/${finalAttrs.resolution}/viewbox.png $out/share/grub/themes/graphite/viewbox.png
      install -Dm444 $src/other/grub2/assets/${assetsDir}/${finalAttrs.resolution}/info.png $out/share/grub/themes/graphite/info.png

      # Make theme.txt writable before modifying it
      chmod +w $out/share/grub/themes/graphite/theme.txt
      # Patch theme.txt to use available DejaVu Sans fonts instead of missing Unifont
      substituteInPlace $out/share/grub/themes/graphite/theme.txt \
        --replace-fail "Unifont Regular 16" "DejaVu Sans Regular ${finalAttrs.fontSize}"

      runHook postInstall
    '';

  meta = {
    description = "Graphite GRUB2 theme by vinceliuice";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
})
