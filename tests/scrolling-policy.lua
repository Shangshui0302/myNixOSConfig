-- Run from the repository root with Lua. These mocked event checks assert
-- dispatch/config command contracts; they do not exercise a live compositor.
local callbacks, commands, timers, state

local function reset()
    callbacks, commands, timers = {}, {}, {}
    state = { windows = {}, active = nil, fit = 0, failMove = false, refocusOnMove = false }
    hl = {
        on = function(event, callback) callbacks[event] = callback end,
        timer = function(callback, options)
            timers[#timers + 1] = { callback = callback, delay = options.timeout }
        end,
        get_windows = function(options)
            local result = {}
            for _, window in ipairs(state.windows) do
                if (not options or options.mapped == false or window.mapped)
                    and (not options or options.floating ~= false or not window.floating)
                    and (not options or not options.workspace or window.workspace.id == options.workspace.id) then
                    result[#result + 1] = window
                end
            end
            return result
        end,
        get_active_window = function() return state.active end,
        get_config = function(path)
            if path == "scrolling:focus_fit_method" then return state.fit end
            if path == "general:gaps_out" then return { left = 5, right = 5 } end
            if path == "general:border_size" then return 2 end
            error("unexpected config lookup: " .. path)
        end,
        config = function(config)
            if config.scrolling then
                state.fit = config.scrolling.focus_fit_method
                commands[#commands + 1] = { kind = "config", fit = state.fit }
            end
        end,
        dsp = {
            window = {
                pseudo = function(args) return { kind = "pseudo", args = args } end,
                resize = function(args) return { kind = "resize", args = args } end,
            },
            layout = function(message) return { kind = "layout", message = message } end,
            focus = function(args) return { kind = "focus", args = args } end,
        },
        dispatch = function(command)
            commands[#commands + 1] = command
            if command.kind == "layout" and command.message:match("^move ") then
                if state.failMove then error("mock move failed") end
                if state.refocusOnMove then state.active = state.refocusOnMove end
            end
            if command.kind == "focus" then state.active = command.args.window end
        end,
    }
    dofile("home/de/hyprland/scrolling-policy.lua")
end

local function runDelay(delay)
    local due, later = {}, {}
    for _, timer in ipairs(timers) do
        if timer.delay == delay then due[#due + 1] = timer else later[#later + 1] = timer end
    end
    timers = later
    for _, timer in ipairs(due) do timer.callback() end
end

local function count(kind)
    local total = 0
    for _, command in ipairs(commands) do
        if command.kind == kind then total = total + 1 end
    end
    return total
end

local function last(kind)
    for index = #commands, 1, -1 do
        if commands[index].kind == kind then return commands[index] end
    end
end

local function monitor()
    return {
        x = 0, width = 2880, height = 1800, scale = 1.5, transform = 0,
        reserved = { left = 0, right = 0, top = 42, bottom = 0 },
    }
end

local function window(address, index, x, width)
    return {
        address = address, mapped = true, hidden = false, floating = false,
        fullscreen = 0, workspace = { id = 1 }, monitor = monitor(),
        at = { x = x or 7, y = 42 }, size = { x = width or 600, y = 800 },
        layout = { name = "scrolling", column = { index = index, width = 0.8 } },
    }
end

local function event(name)
    assert(callbacks[name], "missing event subscription: " .. name)
    callbacks[name]()
end

reset()
assert(callbacks["config.reloaded"], "policy subscribes before settings reload")
assert(#timers == 0 and #commands == 0, "loading only registers events")
event("config.reloaded")
assert(#timers == 0 and #commands == 0, "empty-session reload does not create a timer")
local solo = window("solo", 0)
state.windows = { solo }
state.active = solo
event("window.open")
assert(#timers == 1 and count("pseudo") == 0, "window.open defers policy commands until its timer runs")
runDelay(60)
assert(count("pseudo") == 1 and last("pseudo").args.window == solo, "single mapped window enters pseudo mode")
assert(count("resize") == 2, "single window resets old pseudo size then applies 75 percent")
local sizing = last("resize").args
assert(sizing.x == 1440 and sizing.y == 900 and sizing.relative == false,
    "75 percent uses logical 1920x1200 monitor dimensions")

-- update_rules and ordinary focus preserve the user's later size adjustment.
solo.size.x = 777
event("window.update_rules")
runDelay(60)
event("window.active")
runDelay(16)
assert(count("resize") == 2, "rules update and refocus do not reapply initial dimensions")

-- A close event arrives before mapped becomes false; delayed reconciliation sees
-- the completed close, removes ownership, and gives the remaining solo window 75%.
local second = window("second", 1)
state.windows[#state.windows + 1] = second
state.active = solo
event("window.open")
runDelay(60)
assert(count("pseudo") == 2 and last("pseudo").args.action == "disable",
    "two tiled windows leave solo pseudo mode")
local commandsBeforeClose = #commands
event("window.close")
assert(#commands == commandsBeforeClose, "window.close schedules reconciliation without immediate commands")
solo.mapped = false
state.active = second
runDelay(60)
assert(count("pseudo") == 3 and last("pseudo").args.window == second,
    "close is reconciled after mapped=false and the remaining window re-enters pseudo")
assert(count("resize") == 4, "returning to one window restores 75 percent")

-- Floating and hidden windows are ignored. A real fullscreen window remains a
-- tiled workspace member, so it prevents the other window from being treated
-- as solo; the fullscreen window itself never receives a policy operation.
reset()
local tiled = window("tiled", 0)
local float = window("float", 1); float.floating = true
local hidden = window("hidden", 2); hidden.hidden = true
local fullscreen = window("fullscreen", 3); fullscreen.fullscreen = 2
state.windows = { tiled, float, hidden, fullscreen }
state.active = tiled
event("config.reloaded")
runDelay(60)
assert(count("pseudo") == 0 and count("resize") == 0,
    "floating/hidden are ignored while a real fullscreen tile prevents solo pseudo sizing")
assert(count("layout") == 0, "already aligned tiled geometry is unchanged around a fullscreen workspace member")
state.active = fullscreen
event("window.active")
runDelay(16)
assert(count("layout") == 0, "active true fullscreen window is excluded from edge alignment")

reset()
fullscreen = window("fullscreen-only", 0)
fullscreen.fullscreen = 2
state.windows, state.active = { fullscreen }, fullscreen
event("config.reloaded")
runDelay(60)
assert(count("pseudo") == 0 and count("resize") == 0,
    "a fullscreen-only workspace window is never pseudo-sized")

-- Multi-column entry disables the owned pseudo window without changing the
-- user's column width. Edge movement keeps width/focus-fit and repairs native
-- focus changes when a column has been narrowed below half width.
reset()
local left = window("left", 0, 0, 600)
local middle = window("middle", 1, 700, 600)
local right = window("right", 2, 1200, 713)
state.windows = { left, middle, right }
state.active = left
state.fit = 0
event("config.reloaded")
runDelay(60)
assert(count("pseudo") == 0 and count("resize") == 0, "multi-column workspace never gets solo pseudo sizing")
assert(count("layout") == 1 and last("layout").message == "move +7.000",
    "left edge aligns to reserved gap and border")
assert(state.fit == 0 and last("config").fit == 0, "move restores focus_fit_method")
assert(left.layout.column.width == 0.8, "edge move does not resize the column")

commands = {}
state.active = right
right.at.x = 1200
right.size.x = 700
event("window.active")
runDelay(16)
assert(count("layout") == 1 and last("layout").message == "move +13.000",
    "right edge aligns against monitor width, reserved area, gap, and border")
assert(state.fit == 0 and last("config").fit == 0, "right edge move restores focus_fit_method")
assert(right.layout.column.width == 0.8, "right edge move preserves column width")

commands = {}
left.at.x = 10
left.layout.column.width = 0.4
state.active = left
state.refocusOnMove = middle
event("window.active")
runDelay(16)
assert(count("layout") == 1 and last("layout").message == "move -3.000", "second edge move uses current geometry")
assert(state.active == left and count("focus") == 1,
    "narrow edge move restores focus changed by native scrolling behavior")
assert(state.fit == 0, "narrow edge move restores focus_fit_method 0")

-- Interior and lone-column focus must never issue a move.
commands = {}
state.active = middle
event("window.active")
runDelay(16)
assert(count("layout") == 0, "middle column is not moved")
state.windows = { left }
state.active = left
event("workspace.active")
runDelay(16)
assert(count("layout") == 0, "a single column keeps its full-width slot")

-- A failed move still restores the temporary fit mode and propagates the error.
reset()
left, middle = window("left", 0, 0, 600), window("middle", 1, 700, 600)
state.windows, state.active, state.fit = { left, middle }, left, 0
state.failMove = true
event("config.reloaded")
local ok, err = pcall(function() runDelay(60) end)
assert(not ok and tostring(err):match("mock move failed"), "move errors are propagated from the timer callback")
assert(state.fit == 0 and count("config") == 2 and last("config").fit == 0,
    "focus_fit_method is restored even when move dispatch fails")

print("Scrolling policy mocked event checks passed")
