overlay_path := env("NIX_CONFIG_LOCAL_USER", "/etc/nixos/local/default.nix")
state_path := "/etc/nixos/local/state.json"

[doc('Print the local overlay path')]
[no-cd]
path:
    @echo "{{ overlay_path }}"

[doc('Check that the local overlay and state contract exist')]
[no-cd]
check:
    @if [ ! -f "{{ overlay_path }}" ]; then echo "Missing local overlay shim: {{ overlay_path }}"; echo "Run: just overlay apply"; exit 1; fi
    @if [ ! -f "{{ state_path }}" ]; then echo "Missing local state contract: {{ state_path }}"; echo "Run: just overlay apply --configure"; exit 1; fi
    @echo "Local overlay exists: {{ overlay_path }}"
    @echo "Local state contract exists: {{ state_path }}"

[doc('Preview local overlay template synchronization')]
[no-cd]
sync *args:
    nu scripts/local/sync.nu {{ args }}

[doc('Apply local overlay template synchronization')]
[no-cd]
apply *args:
    doas nu scripts/local/sync.nu --apply {{ args }}
