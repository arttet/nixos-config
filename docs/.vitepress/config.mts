import { defineConfig } from "vitepress";

const userSidebar = [
  {
    text: "Getting Started",
    items: [
      { text: "Overview", link: "/user/" },
      { text: "Quick Start", link: "/user/installation/" },
    ],
  },
  {
    text: "Installation",
    items: [
      { text: "Install Workstation", link: "/user/installation/workstation" },
      { text: "VM", link: "/user/installation/vm" },
    ],
  },
  {
    text: "Daily Use",
    items: [
      { text: "Operations Overview", link: "/user/operations/" },
      { text: "Updates & Rebuilds", link: "/user/operations/rebuild" },
      { text: "Maintenance & Cleanup", link: "/user/operations/cleanup" },
      { text: "Backups", link: "/user/operations/backups" },
      { text: "Recovery & Rollbacks", link: "/user/operations/recovery" },
    ],
  },
  {
    text: "Diagnostics",
    items: [
      { text: "Diagnostics Overview", link: "/user/diagnostics/" },
      { text: "GRUB & Early Boot", link: "/user/diagnostics/grub" },
      { text: "Boot Time", link: "/user/diagnostics/boot" },
      { text: "Disk Space", link: "/user/diagnostics/disk" },
      { text: "Security & Auditing", link: "/user/diagnostics/security" },
      { text: "Networking", link: "/user/diagnostics/network" },
    ],
  },
];

const devSidebar = [
  {
    text: "Engineering Setup",
    items: [
      { text: "Overview", link: "/dev/" },
      { text: "Host Configuration", link: "/dev/setup/" },
      { text: "Windows WSL2", link: "/dev/setup/wsl" },
    ],
  },
  {
    text: "Platform Architecture",
    items: [
      { text: "Architecture Overview", link: "/dev/system/" },
      { text: "System Design", link: "/dev/system/architecture" },
      { text: "Security & Network", link: "/dev/system/security" },
      { text: "Storage & Data", link: "/dev/system/storage" },
      { text: "Boot UX", link: "/dev/system/boot-ux" },
      { text: "System Tuning", link: "/dev/system/tuning" },
      { text: "Workstation Applications", link: "/dev/system/applications" },
      { text: "Workstation Freeze", link: "/dev/system/workstation-freeze" },
    ],
  },
  {
    text: "Development Workflows",
    items: [
      { text: "Workflow Overview", link: "/dev/workflows/" },
      { text: "Git Workflow", link: "/dev/workflows/git-workflow" },
      { text: "Testing", link: "/dev/workflows/testing" },
      { text: "Build Model", link: "/dev/workflows/build-model" },
      { text: "Command Reference", link: "/dev/workflows/commands" },
    ],
  },
  {
    text: "Roadmap",
    items: [
      { text: "Roadmap Overview", link: "/dev/roadmap/" },
      { text: "GUI Stack", link: "/dev/roadmap/gui" },
      { text: "Deferred Features", link: "/dev/roadmap/deferred-features" },
    ],
  },
  {
    text: "Reference",
    items: [
      { text: "Reference Overview", link: "/dev/reference/" },
      { text: "Repository Layout", link: "/dev/reference/layouts" },
      { text: "Just Commands", link: "/dev/reference/just" },
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
      { text: "User Guide", link: "/user/", activeMatch: "/user/" },
      { text: "Engineering", link: "/dev/", activeMatch: "/dev/" },
      { text: "Evolution", link: "/evolution/adr/", activeMatch: "/evolution/" },
    ],

    sidebar: {
      "/user/": userSidebar,
      "/dev/": devSidebar,
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
