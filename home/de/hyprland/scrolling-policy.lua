-- Hyprland 0.56: pseudo is a static window rule, so window-count transitions
-- need events. Change defaults only on entry; ordinary refocus must keep edits.
local singleWindows = {}
local pending = {}
local busy = false

local function setPseudo(window, enabled)
    hl.dispatch(hl.dsp.window.pseudo({
        window = window,
        action = enabled and "enable" or "disable",
    }))
end

local function monitorSize(monitor)
    local width, height = monitor.width / monitor.scale, monitor.height / monitor.scale
    if monitor.transform % 2 == 1 then width, height = height, width end
    return width, height
end

local function updateSingleWindows()
    local counts, windows = {}, {}
    for _, window in ipairs(hl.get_windows({ mapped = true, floating = false })) do
        local workspace, layout = window.workspace, window.layout
        if workspace and not window.hidden and layout and layout.name == "scrolling" then
            windows[window.address] = window
            counts[workspace.id] = (counts[workspace.id] or 0) + 1
        end
    end

    for address, window in pairs(singleWindows) do
        local current = windows[address]
        if not current or counts[current.workspace.id] ~= 1 then
            if window.mapped then setPseudo(window, false) end
            singleWindows[address] = nil
        end
    end

    for address, window in pairs(windows) do
        if counts[window.workspace.id] == 1 and not singleWindows[address]
            and window.fullscreen == 0 and window.monitor then
            local width, height = monitorSize(window.monitor)
            singleWindows[address] = window
            setPseudo(window, true)
            -- Reset any old oversized pseudo dimensions by clamping them to the
            -- tile first. Absolute resize otherwise uses the scaled visual size.
            hl.dispatch(hl.dsp.window.resize({
                window = window, x = width * 2, y = height * 2, relative = false,
            }))
            hl.dispatch(hl.dsp.window.resize({
                window = window, x = math.floor(width * 0.75), y = math.floor(height * 0.75), relative = false,
            }))
        end
    end
end

local function alignEdgeColumn()
    local window = hl.get_active_window()
    if not window or window.floating or window.fullscreen ~= 0 or not window.workspace then return end
    local layout = window.layout
    if not layout or layout.name ~= "scrolling" or not layout.column then return end

    local first, last, count, seen = math.huge, -math.huge, 0, {}
    for _, other in ipairs(hl.get_windows({ workspace = window.workspace, floating = false })) do
        local otherLayout = other.layout
        if not other.hidden and otherLayout and otherLayout.name == "scrolling" and otherLayout.column then
            local index = otherLayout.column.index
            if not seen[index] then
                seen[index] = true
                first, last, count = math.min(first, index), math.max(last, index), count + 1
            end
        end
    end
    -- A lone column retains its full-width slot, including stacked windows.
    if count < 2 or not window.monitor then return end

    local monitor, index = window.monitor, layout.column.index
    local gaps, border = hl.get_config("general:gaps_out"), hl.get_config("general:border_size")
    local width = monitorSize(monitor)
    local delta
    if index == first then
        delta = monitor.x + monitor.reserved.left + gaps.left + border - window.at.x
    elseif index == last then
        delta = monitor.x + width - monitor.reserved.right - gaps.right - border - window.at.x - window.size.x
    else
        return
    end
    if math.abs(delta) <= 1 then return end

    -- Native scrolling move refocuses the column under the viewport center.
    -- Temporarily use fit mode so that refocus cannot recenter the edge column;
    -- restore the original focus too when a manually narrowed column is < 50%.
    local previousFit = hl.get_config("scrolling:focus_fit_method")
    hl.config({ scrolling = { focus_fit_method = 1 } })
    local ok, err = pcall(function()
        hl.dispatch(hl.dsp.layout(string.format("move %+.3f", delta)))
        local active = hl.get_active_window()
        if not active or active.address ~= window.address then
            hl.dispatch(hl.dsp.focus({ window = window }))
        end
    end)
    hl.config({ scrolling = { focus_fit_method = previousFit } })
    if not ok then error(err) end
end

local function schedule(delay, updateSingles)
    if busy or pending[delay] then return end
    pending[delay] = true
    hl.timer(function()
        pending[delay] = nil
        busy = true
        local ok, err = pcall(function()
            if updateSingles then updateSingleWindows() end
            alignEdgeColumn()
        end)
        busy = false
        if not ok then error(err) end
    end, { timeout = delay, type = "oneshot" })
end

for _, event in ipairs({ "window.active", "workspace.active", "workspace.special_active" }) do
    hl.on(event, function() schedule(16, false) end)
end

-- close/update_rules are emitted before removal/retile is finished. Reconcile
-- once after the event burst, then align after the pseudo change, without polling.
for _, event in ipairs({
    "window.open", "window.close", "window.destroy", "window.move_to_workspace",
    "window.update_rules", "window.fullscreen", "monitor.layout_changed",
}) do
    hl.on(event, function() schedule(60, true) end)
end
-- extraLuaFiles loads before settings. Initialize existing windows after reload;
-- an empty session waits for window.open. This also avoids creating timers in
-- 0.56's offline verifier, which has no event loop for timer cleanup.
hl.on("config.reloaded", function()
    if #hl.get_windows() > 0 then schedule(60, true) end
end)
-- Hyprland removes subscriptions and timers on reload.
