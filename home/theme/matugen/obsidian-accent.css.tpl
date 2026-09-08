/*
 * Matugen accent palette for Obsidian.
 * Minimal/Claude for Minimal keep ownership of surfaces, typography, and layout.
 */

body.theme-light,
body.theme-light.minimal-light-white,
body.theme-light.minimal-light-tonal,
body.theme-light.minimal-light-contrast {
  --matugen-accent: {{colors.primary.light.hex}};
  --matugen-accent-hover: {{colors.secondary.light.hex}};
  --matugen-accent-soft: rgba({{colors.primary.light.red}}, {{colors.primary.light.green}}, {{colors.primary.light.blue}}, 0.14);

  --accent-h: {{colors.primary.light.hue}};
  --accent-s: {{colors.primary.light.saturation}}%;
  --accent-l: {{colors.primary.light.lightness}}%;
  --interactive-accent-rgb: {{colors.primary.light.red}}, {{colors.primary.light.green}}, {{colors.primary.light.blue}};
  --color-accent-rgb: var(--interactive-accent-rgb);
  --color-accent: var(--matugen-accent);
  --color-accent-1: {{colors.primary_container.light.hex}};
  --color-accent-2: {{colors.secondary.light.hex}};
  --text-on-accent: {{colors.on_primary.light.hex}};

  --accent-color: var(--matugen-accent);
  --claude-accent: var(--matugen-accent);
  --claude-accent-hover: var(--matugen-accent-hover);
  --claude-accent-soft: var(--matugen-accent-soft);
  --ax1: var(--matugen-accent);
  --ax2: var(--matugen-accent-hover);
  --ax3: var(--matugen-accent);
  --sp1: {{colors.on_primary.light.hex}};
  --hl1: rgba({{colors.primary.light.red}}, {{colors.primary.light.green}}, {{colors.primary.light.blue}}, 0.30);
  --hl2: var(--matugen-accent-soft);

  --background-modifier-accent: var(--matugen-accent);
  --background-modifier-border-focus: var(--matugen-accent);
  --text-accent: var(--matugen-accent);
  --text-accent-hover: var(--matugen-accent-hover);
  --interactive-accent: var(--matugen-accent);
  --interactive-accent-hover: var(--matugen-accent-hover);
  --link-color: var(--matugen-accent);
  --link-color-hover: var(--matugen-accent-hover);
  --link-external-color: var(--matugen-accent);
  --link-external-color-hover: var(--matugen-accent-hover);
  --checkbox-color: var(--matugen-accent);
  --checkbox-color-hover: var(--matugen-accent-hover);
  --nav-item-background-active: var(--matugen-accent-soft);
  --text-highlight-bg: var(--matugen-accent-soft);
  --text-highlight-bg-active: rgba({{colors.primary.light.red}}, {{colors.primary.light.green}}, {{colors.primary.light.blue}}, 0.24);
}

body.theme-dark,
body.theme-dark.minimal-dark,
body.theme-dark.minimal-dark-tonal,
body.theme-dark.minimal-dark-black {
  --matugen-accent: {{colors.primary.dark.hex}};
  --matugen-accent-hover: {{colors.secondary.dark.hex}};
  --matugen-accent-soft: rgba({{colors.primary.dark.red}}, {{colors.primary.dark.green}}, {{colors.primary.dark.blue}}, 0.22);

  --accent-h: {{colors.primary.dark.hue}};
  --accent-s: {{colors.primary.dark.saturation}}%;
  --accent-l: {{colors.primary.dark.lightness}}%;
  --interactive-accent-rgb: {{colors.primary.dark.red}}, {{colors.primary.dark.green}}, {{colors.primary.dark.blue}};
  --color-accent-rgb: var(--interactive-accent-rgb);
  --color-accent: var(--matugen-accent);
  --color-accent-1: {{colors.primary_container.dark.hex}};
  --color-accent-2: {{colors.secondary.dark.hex}};
  --text-on-accent: {{colors.on_primary.dark.hex}};

  --accent-color: var(--matugen-accent);
  --claude-accent: var(--matugen-accent);
  --claude-accent-hover: var(--matugen-accent-hover);
  --claude-accent-soft: var(--matugen-accent-soft);
  --ax1: var(--matugen-accent);
  --ax2: var(--matugen-accent-hover);
  --ax3: var(--matugen-accent);
  --sp1: {{colors.on_primary.dark.hex}};
  --hl1: rgba({{colors.primary.dark.red}}, {{colors.primary.dark.green}}, {{colors.primary.dark.blue}}, 0.34);
  --hl2: var(--matugen-accent-soft);

  --background-modifier-accent: var(--matugen-accent);
  --background-modifier-border-focus: var(--matugen-accent);
  --text-accent: var(--matugen-accent);
  --text-accent-hover: var(--matugen-accent-hover);
  --interactive-accent: var(--matugen-accent);
  --interactive-accent-hover: var(--matugen-accent-hover);
  --link-color: var(--matugen-accent);
  --link-color-hover: var(--matugen-accent-hover);
  --link-external-color: var(--matugen-accent);
  --link-external-color-hover: var(--matugen-accent-hover);
  --checkbox-color: var(--matugen-accent);
  --checkbox-color-hover: var(--matugen-accent-hover);
  --nav-item-background-active: var(--matugen-accent-soft);
  --text-highlight-bg: var(--matugen-accent-soft);
  --text-highlight-bg-active: rgba({{colors.primary.dark.red}}, {{colors.primary.dark.green}}, {{colors.primary.dark.blue}}, 0.32);
}
