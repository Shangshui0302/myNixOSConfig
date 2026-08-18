hl.config({
  general = {
    ["col.active_border"] = "{{colors.primary.dark.hex}}",
    ["col.inactive_border"] = "{{colors.outline.dark.hex}}",
  },
  group = {
    ["col.border_active"] = "{{colors.primary.dark.hex}}",
    ["col.border_inactive"] = "{{colors.outline.dark.hex}}",
    ["col.border_locked_active"] = "{{colors.error.dark.hex}}",
    ["col.border_locked_inactive"] = "{{colors.outline.dark.hex}}",
    groupbar = {
      ["col.active"] = "{{colors.primary.dark.hex}}",
      ["col.inactive"] = "{{colors.outline.dark.hex}}",
      ["col.locked_active"] = "{{colors.error.dark.hex}}",
      ["col.locked_inactive"] = "{{colors.outline.dark.hex}}",
    },
  },
})
