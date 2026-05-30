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

  installPhase =
    let
      colorSuffix = if finalAttrs.variant == "nord" then "-nord" else "";
      assetsDir = if finalAttrs.variant == "nord" then "assets-nord" else "assets";
    in
    ''
      runHook preInstall

      mkdir -p $out/share/grub/themes/graphite

      # Common files (terminal boxes, fonts)
      cp $src/other/grub2/common/*.png $out/share/grub/themes/graphite/
      cp $src/other/grub2/common/*.pf2 $out/share/grub/themes/graphite/

      # Theme config
      cp $src/other/grub2/config/theme-${finalAttrs.resolution}.txt $out/share/grub/themes/graphite/theme.txt

      # Background
      cp $src/other/grub2/backgrounds/${finalAttrs.resolution}/wave-dark${colorSuffix}.png $out/share/grub/themes/graphite/background.png

      # Icons (OS logos)
      cp -r $src/other/grub2/assets/logos${colorSuffix}/${finalAttrs.resolution} $out/share/grub/themes/graphite/icons

      # Assets (select_*.png, viewbox.png, info.png)
      cp $src/other/grub2/assets/${assetsDir}/${finalAttrs.resolution}/*.png $out/share/grub/themes/graphite/

      runHook postInstall
    '';

  meta = {
    description = "Graphite GRUB2 theme by vinceliuice";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
})
