hl.config({
  general = {
        ["col.active_border"] = "{{colors.primary.default.hex}}",
        ["col.inactive_border"] = "{{colors.outline.default.hex}}",
  },
  group = {
        ["col.border_active"] = "{{colors.primary.default.hex}}",
        ["col.border_inactive"] = "{{colors.outline.default.hex}}",
        ["col.border_locked_active"] = "{{colors.error.default.hex}}",
        ["col.border_locked_inactive"] = "{{colors.outline.default.hex}}",
    groupbar = {
          ["col.active"] = "{{colors.primary.default.hex}}",
          ["col.inactive"] = "{{colors.outline.default.hex}}",
          ["col.locked_active"] = "{{colors.error.default.hex}}",
          ["col.locked_inactive"] = "{{colors.outline.default.hex}}",
    },
  },
})
