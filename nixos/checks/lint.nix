{
  lib,
  pkgs,
  root,
}:
let
  cleanSource = lib.cleanSourceWith {
    src = lib.cleanSource root;
    filter =
      path: type:
      let
        rel = lib.removePrefix "/" (lib.removePrefix (toString root) (toString path));
      in
      rel != "docs"
      && rel != "target"
      && !(lib.hasPrefix "docs/" rel)
      && !(lib.hasPrefix "target/" rel)
      && type != "symlink";
  };
in
{
  deadnix = pkgs.runCommand "deadnix" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
    cd ${cleanSource}
    deadnix --fail .
    touch $out
  '';
  statix = pkgs.runCommand "statix" { nativeBuildInputs = [ pkgs.statix ]; } ''
    cd ${cleanSource}
    statix check .
    touch $out
  '';
  json-schemas = pkgs.runCommand "json-schemas" { nativeBuildInputs = [ pkgs.check-jsonschema ]; } ''
    shopt -s nullglob
    cd ${cleanSource}
    check-jsonschema --check-metaschema schemas/*.schema.json
    check-jsonschema --schemafile schemas/platform-state.v1.schema.json schemas/fixtures/platform-state.*.valid.json
    for fixture in schemas/fixtures/platform-state.*.invalid.json; do
      if check-jsonschema --schemafile schemas/platform-state.v1.schema.json "$fixture" >/dev/null 2>&1; then
        echo "invalid platform state fixture $fixture unexpectedly passed schema validation" >&2
        exit 1
      fi
    done
    touch $out
  '';
}
