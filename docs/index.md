---
layout: home

hero:
  name: NixOS Platform
  text: Personal Reproducible NixOS Infrastructure
  tagline: Declarative systems, disposable machines, and local identity without turning the repository into snowflake state.
  actions:
    - theme: brand
      text: 🚀 User Guide
      link: /user/migration
    - theme: alt
      text: 🏗 Engineering Guide
      link: /dev/setup/wsl

features:
  - icon: 🧱
    title: Layered Architecture
    details: Public infrastructure, local overlays, generated artifacts, and machine identity remain intentionally separated.
  - icon: 🔁
    title: Disposable Systems
    details: Rebuild the local NixOS VM mirror before applying changes to real hardware.
  - icon: 🔐
    title: Local Identity
    details: Real users, SSH keys, hardware state, and secrets never enter the repository.
  - icon: ⚡
    title: Fast DX Loop
    details: Small repeatable workflows keep builds, validation, cleanup, and iteration predictable during daily development.
  - icon: 📐
    title: Documentation Driven
    details: Architecture, operating contracts, and workflows evolve beside the implementation instead of drifting separately.
  - icon: 🧭
    title: Incremental Platform
    details: The system grows milestone by milestone from VM validation toward workstation installs, encryption, CI, and future infrastructure targets.

---
