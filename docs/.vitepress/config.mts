import { defineConfig } from "vitepress";

const userSidebar = [
  {
    text: "Getting Started",
    items: [
      { text: "Overview", link: "/user/installation" },
    ],
  },
  {
    text: "Installation",
    items: [
      { text: "Install Workstation", link: "/user/install-workstation" },
      { text: "VM", link: "/user/install-vm" },
    ],
  },
  {
    text: "Daily Use",
    items: [
      { text: "Updates & Rebuilds", link: "/user/ops-rebuild" },
      { text: "Maintenance & Cleanup", link: "/user/ops-cleanup" },
      { text: "Backups", link: "/user/ops-backups" },
      { text: "Recovery & Rollbacks", link: "/user/ops-recovery" },
    ],
  },
  {
    text: "Diagnostics",
    items: [
      { text: "GRUB & Early Boot", link: "/user/diag-grub" },
      { text: "Boot Time", link: "/user/diag-boot" },
      { text: "Disk Space", link: "/user/diag-disk" },
      { text: "Security & Auditing", link: "/user/diag-security" },
      { text: "Networking", link: "/user/diag-network" },
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
      { text: "Boot UX", link: "/dev/system/boot-ux" },
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
  {
    text: "Reference",
    items: [
      { text: "Repository Layout", link: "/reference/layouts" },
      { text: "Just Commands", link: "/reference/just" },
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
      { text: "User Guide", link: "/user/installation", activeMatch: "/user/" },
      { text: "Engineering", link: "/dev/setup/wsl", activeMatch: "/dev/|/reference/" },
      { text: "Evolution", link: "/evolution/adr/", activeMatch: "/evolution/" },
    ],

    sidebar: {
      "/user/": userSidebar,
      "/dev/": devSidebar,
      "/reference/": devSidebar,
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
