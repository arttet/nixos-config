# Recovery

The recovery model is rebuild-first.

If a guest VM is broken, delete its state and rebuild it. If a real machine is
broken in a future milestone, the platform should provide enough documented
state to recreate it rather than preserve unknown drift.
