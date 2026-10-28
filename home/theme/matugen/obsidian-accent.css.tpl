/* Optional Border Notion palette; enabled by the Style Settings class. */

body.hln-palette-matugen.theme-light {
  --hln-link: {{colors.primary.light.hex}};
  --hln-marker: rgba({{colors.primary.light.red}}, {{colors.primary.light.green}}, {{colors.primary.light.blue}}, 0.20);
  --hln-marker-text: var(--hln-ink);
  --hln-marker-soft: var(--hln-marker);
  --hln-selection: rgba({{colors.primary.light.red}}, {{colors.primary.light.green}}, {{colors.primary.light.blue}}, 0.22);
  --hln-note-rgb: {{colors.primary.light.red}}, {{colors.primary.light.green}}, {{colors.primary.light.blue}};
  --accent-h: {{colors.primary.light.hue}};
  --accent-s: {{colors.primary.light.saturation}}%;
  --accent-l: {{colors.primary.light.lightness}}%;
  --interactive-accent-rgb: {{colors.primary.light.red}}, {{colors.primary.light.green}}, {{colors.primary.light.blue}};
  --color-accent-rgb: {{colors.primary.light.red}}, {{colors.primary.light.green}}, {{colors.primary.light.blue}};
  --text-on-accent: {{colors.on_primary.light.hex}};
  --sp1: {{colors.on_primary.light.hex}};
  --color-accent: {{colors.primary.light.hex}};
  --color-accent-1: {{colors.primary.light.hex}};
  --color-accent-2: {{colors.primary.light.hex}};
  --interactive-accent: {{colors.primary.light.hex}};
  --link-color: {{colors.primary.light.hex}};
  --link-external-color: {{colors.primary.light.hex}};
  --checkbox-color: {{colors.primary.light.hex}};
  --text-accent: {{colors.primary.light.hex}};
  --interactive-accent-hover: {{colors.secondary.light.hex}};
  --link-color-hover: {{colors.secondary.light.hex}};
  --link-external-color-hover: {{colors.secondary.light.hex}};
  --checkbox-color-hover: {{colors.secondary.light.hex}};
  --text-accent-hover: {{colors.secondary.light.hex}};
  --checkbox-marker-color: {{colors.on_primary.light.hex}};
  --text-highlight-bg: var(--hln-marker);
  --text-highlight-bg-active: var(--hln-marker);
}

body.hln-palette-matugen.theme-dark {
  --hln-link: {{colors.primary.dark.hex}};
  --hln-marker: rgba({{colors.primary.dark.red}}, {{colors.primary.dark.green}}, {{colors.primary.dark.blue}}, 0.28);
  --hln-marker-text: var(--hln-ink);
  --hln-marker-soft: var(--hln-marker);
  --hln-selection: rgba({{colors.primary.dark.red}}, {{colors.primary.dark.green}}, {{colors.primary.dark.blue}}, 0.22);
  --hln-note-rgb: {{colors.primary.dark.red}}, {{colors.primary.dark.green}}, {{colors.primary.dark.blue}};
  --accent-h: {{colors.primary.dark.hue}};
  --accent-s: {{colors.primary.dark.saturation}}%;
  --accent-l: {{colors.primary.dark.lightness}}%;
  --interactive-accent-rgb: {{colors.primary.dark.red}}, {{colors.primary.dark.green}}, {{colors.primary.dark.blue}};
  --color-accent-rgb: {{colors.primary.dark.red}}, {{colors.primary.dark.green}}, {{colors.primary.dark.blue}};
  --text-on-accent: {{colors.on_primary.dark.hex}};
  --sp1: {{colors.on_primary.dark.hex}};
  --color-accent: {{colors.primary.dark.hex}};
  --color-accent-1: {{colors.primary.dark.hex}};
  --color-accent-2: {{colors.primary.dark.hex}};
  --interactive-accent: {{colors.primary.dark.hex}};
  --link-color: {{colors.primary.dark.hex}};
  --link-external-color: {{colors.primary.dark.hex}};
  --checkbox-color: {{colors.primary.dark.hex}};
  --text-accent: {{colors.primary.dark.hex}};
  --interactive-accent-hover: {{colors.secondary.dark.hex}};
  --link-color-hover: {{colors.secondary.dark.hex}};
  --link-external-color-hover: {{colors.secondary.dark.hex}};
  --checkbox-color-hover: {{colors.secondary.dark.hex}};
  --text-accent-hover: {{colors.secondary.dark.hex}};
  --checkbox-marker-color: {{colors.on_primary.dark.hex}};
  --text-highlight-bg: var(--hln-marker);
  --text-highlight-bg-active: var(--hln-marker);
}
