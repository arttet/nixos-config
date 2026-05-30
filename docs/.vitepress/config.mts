import { defineConfig } from "vitepress";

const userSidebar = [
  {
    text: "Getting Started",
    items: [
      { text: "Overview", link: "/user/" },
      { text: "Quick Start", link: "/user/quickstart" },
    ],
  },
  {
    text: "Installation",
    items: [
      { text: "Workstation", link: "/user/installation/workstation" },
      { text: "VM", link: "/user/installation/vm" },
    ],
  },
  {
    text: "Daily Use",
    items: [
      { text: "Overview", link: "/user/operations/" },
      { text: "Updates & Rebuilds", link: "/user/operations/rebuild" },
      { text: "Maintenance & Cleanup", link: "/user/operations/cleanup" },
      { text: "Backups", link: "/user/operations/backups" },
      { text: "Recovery & Rollbacks", link: "/user/operations/recovery" },
    ],
  },
  {
    text: "Diagnostics",
    items: [
      { text: "Overview", link: "/user/diagnostics/" },
      { text: "GRUB & Early Boot", link: "/user/diagnostics/grub" },
      { text: "Boot Time", link: "/user/diagnostics/boot" },
      { text: "Disk Space", link: "/user/diagnostics/disk" },
      { text: "Security & Auditing", link: "/user/diagnostics/security" },
      { text: "Networking", link: "/user/diagnostics/network" },
    ],
  },
];

const devSidebar = [
  { text: "Overview", link: "/dev/" },
  {
    text: "Local Environment",
    items: [
      { text: "Overview", link: "/dev/setup/" },
      { text: "Mutable Linux", link: "/dev/setup/mutable_linux" },
      { text: "WSL2", link: "/dev/setup/wsl" },
    ],
  },
  {
    text: "Development Guide",
    items: [
      { text: "Overview", link: "/dev/guide/" },
      { text: "Nix Style & Best Practices", link: "/dev/standards/nix-style" },
      { text: "Automated Validation", link: "/dev/reference/validation" },
    ],
  },
  {
    text: "Architecture & Design",
    items: [
      { text: "Architecture Overview", link: "/dev/architecture/layers" },
      { text: "System Composition", link: "/dev/architecture/composition" },
      { text: "Security & Network", link: "/dev/architecture/security" },
      { text: "Storage & Data", link: "/dev/architecture/storage" },
      { text: "Boot UX", link: "/dev/architecture/boot" },
      { text: "System Tuning", link: "/dev/architecture/tuning" },
      { text: "Product Freeze", link: "/dev/architecture/freeze" },
    ],
  },
  {
    text: "Reference",
    items: [
      { text: "Overview", link: "/dev/reference/" },
      { text: "Repository Layout", link: "/dev/reference/layouts" },
      { text: "Just Commands", link: "/dev/reference/just" },
      { text: "CI/CD Pipeline", link: "/dev/reference/cicd" },
    ],
  },
];

const evolutionSidebar = [
  { text: "Overview", link: "/evolution/" },
  {
    text: "Roadmap",
    items: [
      { text: "Overview", link: "/evolution/roadmap/" },
      {
        text: "Deferred Features",
        link: "/evolution/roadmap/deferred-features",
      },
    ],
  },
  {
    text: "Architecture Decisions",
    items: [
      { text: "Overview", link: "/evolution/adr/" },
    ],
  },
];

export default defineConfig({
  title: "NixOS Configuration",
  description: "Personal NixOS Infrastructure",
  cleanUrls: true,
  lastUpdated: true,

  head: [["meta", { name: "theme-color", content: "#6366f1" }]],

  markdown: {
    theme: {
      light: "github-light",
      dark: "github-dark",
    },
  },

  themeConfig: {
    logo: "/logo.svg",
    siteTitle: "NixOS Configuration",

    nav: [
      { text: "Home", link: "/" },
      { text: "User Guide", link: "/user/", activeMatch: "/user/" },
      { text: "Engineering", link: "/dev/", activeMatch: "/dev/" },
      { text: "Evolution", link: "/evolution/", activeMatch: "/evolution/" },
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
