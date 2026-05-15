import { defineConfig } from "vitepress";

const userSidebar = [
  {
    text: "Getting Started",
    items: [
      { text: "Migration Handbook", link: "/user/migration" },
      { text: "Quick Start", link: "/user/installation" },
    ],
  },
  {
    text: "Installation",
    items: [
      { text: "Workstation", link: "/user/install-workstation" },
      { text: "Workstation GUI", link: "/user/workstation-gui" },
      { text: "VM (Local Testing)", link: "/user/install-vm" },
      { text: "Rehearsal", link: "/user/install-rehearsal" },
    ],
  },
  {
    text: "Daily Use",
    items: [
      { text: "Updates & Rebuilds", link: "/user/ops-rebuild" },
      { text: "Maintenance & Cleanup", link: "/user/ops-cleanup" },
      { text: "Backups", link: "/user/ops-backups" },
    ],
  },
  {
    text: "Disaster Recovery",
    items: [
      { text: "Rollbacks", link: "/user/ops-rollback" },
      { text: "System Recovery", link: "/user/ops-recovery" },
    ],
  },
];

const devSidebar = [
  {
    text: "Engineering Setup",
    items: [
      { text: "Development Environment", link: "/dev/setup/wsl" },
    ],
  },
  {
    text: "Platform Architecture",
    items: [
      { text: "System Architecture", link: "/dev/system/architecture" },
      { text: "Security & Network", link: "/dev/system/security" },
      { text: "Storage & Data", link: "/dev/system/storage" },
      { text: "System Tuning", link: "/dev/system/tuning" },
      { text: "Workstation Applications", link: "/dev/system/applications" },
      { text: "Workstation Freeze", link: "/dev/system/workstation-freeze" },
    ],
  },
  {
    text: "Development Workflows",
    items: [
      { text: "Git Workflow", link: "/dev/workflows/git-workflow" },
      { text: "Testing", link: "/dev/workflows/testing" },
      { text: "Build Model", link: "/dev/workflows/build-model" },
      { text: "Command Reference", link: "/dev/workflows/commands" },
    ],
  },
  {
    text: "Roadmap",
    items: [
      { text: "Overview", link: "/dev/roadmap/overview" },
      { text: "GUI Stack", link: "/dev/roadmap/gui" },
      { text: "Deferred Features", link: "/dev/roadmap/deferred-features" },
    ],
  },
];

const referenceSidebar = [
  {
    text: "Technical Contracts",
    items: [
      { text: "Just Commands", link: "/reference/just" },
      { text: "Repository Layout", link: "/reference/layouts" },
      { text: "Flakes", link: "/reference/flakes" },
      { text: "Nushell", link: "/reference/nushell" },
      { text: "QEMU", link: "/reference/qemu" },
    ],
  },
];

const evolutionSidebar = [
  {
    text: "History & Decisions",
    items: [
      { text: "Architecture Decisions", link: "/evolution/adr/" },
    ],
  },
];

export default defineConfig({
  title: "NixOS Platform",
  description: "Personal NixOS Infrastructure",
  cleanUrls: true,
  lastUpdated: true,

  head: [["meta", { name: "theme-color", content: "#2563eb" }]],

  markdown: {
    theme: {
      light: "github-light",
      dark: "github-dark",
    },
  },

  themeConfig: {
    logo: "/logo.svg",
    siteTitle: "NixOS Platform",

    nav: [
      { text: "Home", link: "/" },
      { text: "User Guide", link: "/user/migration", activeMatch: "/user/" },
      { text: "Engineering", link: "/dev/setup/wsl", activeMatch: "/dev/" },
      { text: "Reference", link: "/reference/just", activeMatch: "/reference/" },
      { text: "Evolution", link: "/evolution/adr/", activeMatch: "/evolution/" },
    ],

    sidebar: {
      "/user/": userSidebar,
      "/dev/": devSidebar,
      "/reference/": referenceSidebar,
      "/evolution/": evolutionSidebar,
    },

    search: {
      provider: "local",
    },

    outline: {
      level: [2, 3],
    },

    socialLinks: [
      { icon: "github", link: "https://github.com/arttet/nixos-config" },
    ],

    footer: {
      message: "Platform Documentation",
      copyright: "Copyright © 2026 Artyom Tetyukhin",
    },
  },
});
