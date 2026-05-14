overlay_path := env("NIX_CONFIG_LOCAL_USER", env("HOME", "") / ".nix-config-local/user.nix")

[doc('Print the local user overlay path')]
[no-cd]
path:
    @echo "{{ overlay_path }}"

[doc('Check that the local user overlay exists')]
[no-cd]
check:
    @if [ ! -f "{{ overlay_path }}" ]; then echo "Missing local user overlay: {{ overlay_path }}"; echo "Create it from examples/local/user.nix and keep real identity outside git."; exit 1; fi
    @echo "Local user overlay exists: {{ overlay_path }}"
