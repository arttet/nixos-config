state_path := env("NIX_CONFIG_LOCAL_STATE", "/etc/nixos/local/state.json")

[doc('Print the local state path')]
[no-cd]
path:
    @echo "{{ state_path }}"

[doc('Check that the local state contract exists')]
[no-cd]
check:
    @if [ ! -f "{{ state_path }}" ]; then echo "Missing local state contract: {{ state_path }}"; echo "Run: just overlay apply --configure"; exit 1; fi
    @echo "Local state contract exists: {{ state_path }}"

[doc('Preview local state synchronization')]
[no-cd]
sync *args:
    nu scripts/local/sync.nu {{ args }}

[doc('Apply local state synchronization')]
[no-cd]
apply *args:
    doas nu scripts/local/sync.nu --apply {{ args }}
