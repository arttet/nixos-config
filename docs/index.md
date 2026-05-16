---
layout: home

hero:
  name: NixOS Platform
  text: Personal Reproducible NixOS Infrastructure
  tagline: A declarative NixOS workstation with local identity kept outside the repository.
  actions:
    - theme: brand
      text: 🚀 Quick Start
      link: /user/installation
    - theme: alt
      text: 🏗 Engineering Guide
      link: /dev/setup/wsl

features:
  - icon: 🧱
    title: Layered Architecture
    details: Public infrastructure, local overlays, generated artifacts, and machine identity remain intentionally separated.
  - icon: 🔁
    title: Default Workstation
    details: Install the graphical workstation on clean hardware, then rebuild and roll back through NixOS generations.
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
    title: Disposable VM
    details: Use the disposable VM for local checks without making it the main operating workflow.

---
