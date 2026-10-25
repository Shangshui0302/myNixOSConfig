-- Hyprland 0.56: persistent_size only covers floating Wayland windows.
-- Keep the scrolling column's logical width, including when a lone column
-- temporarily fills the workspace. Reloading the config resets this memory.
local rememberedWidth
local pendingAddress

local function scrollingColumn(window)
    if not window or window.class ~= "token-monitor" or window.floating then
        return nil
    end
    local layout = window.layout
    if layout and layout.name == "scrolling" then
        return layout.column
    end
end

local function restoreWidth(window)
    if not window or window.address ~= pendingAddress or not window.active then
        return
    end
    pendingAddress = nil
    if scrollingColumn(window) then
        -- colresize targets the active column. Wait for this window's focus
        -- instead of changing focus or accidentally resizing another app.
        hl.dispatch(hl.dsp.layout(string.format("colresize %.9f", rememberedWidth)))
    end
end

hl.on("window.close", function(window)
    if window.address == pendingAddress then
        -- An unfocused popup closed before restoration; keep the previous width.
        pendingAddress = nil
        return
    end
    local column = scrollingColumn(window)
    if column then
        rememberedWidth = column.width
    end
end)

hl.on("window.open", function(window)
    if rememberedWidth and scrollingColumn(window) then
        pendingAddress = window.address
        restoreWidth(window)
    end
end)

hl.on("window.active", restoreWidth)
