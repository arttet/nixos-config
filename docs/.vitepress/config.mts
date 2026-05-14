import { defineConfig } from "vitepress";

const platformSidebar = [
  {
    text: "Installation",
    items: [
      { text: "Overview", link: "/installation/" },
      { text: "Windows WSL2", link: "/installation/windows-wsl2" },
      { text: "Workstation", link: "/installation/workstation" },
      { text: "VM", link: "/installation/vm" },
    ],
  },
  {
    text: "Runtime",
    items: [
      { text: "Overview", link: "/runtime/" },
      { text: "VM", link: "/runtime/vm" },
    ],
  },
  {
    text: "Profiles",
    items: [
      { text: "Overview", link: "/profiles/" },
      { text: "Workstation", link: "/profiles/workstation" },
      { text: "VM", link: "/profiles/vm" },
    ],
  },
  {
    text: "Development",
    items: [
      { text: "Overview", link: "/development/" },
      { text: "Workflow", link: "/development/workflow" },
      { text: "Commands", link: "/development/commands" },
      { text: "Testing", link: "/development/testing" },
      { text: "Repository Layout", link: "/development/repository-layout" },
    ],
  },
  {
    text: "Architecture",
    items: [
      { text: "Overview", link: "/architecture/" },
      { text: "Layering", link: "/architecture/layering" },
      { text: "Overlays", link: "/architecture/overlays" },
      { text: "Hardware Layer", link: "/architecture/hardware-layer" },
      { text: "Secrets Model", link: "/architecture/secrets-model" },
      { text: "Storage Model", link: "/architecture/storage-model" },
      { text: "Disk Encryption", link: "/architecture/disk-encryption" },
      { text: "Kernel Policy", link: "/architecture/kernel-policy" },
      { text: "Build Model", link: "/architecture/build-model" },
      { text: "Targets", link: "/architecture/targets" },
      { text: "Roadmap", link: "/architecture/roadmap" },
    ],
  },
  {
    text: "Operations",
    items: [
      { text: "Overview", link: "/operations/" },
      { text: "Rebuilding", link: "/operations/rebuilding" },
      { text: "Cleanup", link: "/operations/cleanup" },
      { text: "Recovery", link: "/operations/recovery" },
      { text: "Rollback", link: "/operations/rollback" },
    ],
  },
  {
    text: "Reference",
    items: [
      { text: "Overview", link: "/reference/" },
      { text: "Just", link: "/reference/just" },
      { text: "Nushell", link: "/reference/nushell" },
      { text: "QEMU", link: "/reference/qemu" },
      { text: "Flakes", link: "/reference/flakes" },
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
      { text: "Platform", link: "/installation/" },
    ],

    sidebar: {
      "/installation/": platformSidebar,
      "/runtime/": platformSidebar,
      "/profiles/": platformSidebar,
      "/development/": platformSidebar,
      "/architecture/": platformSidebar,
      "/operations/": platformSidebar,
      "/reference/": platformSidebar,
      "/": platformSidebar,
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
