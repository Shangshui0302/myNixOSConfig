-- Run from the repository root with Lua. These are mocked event checks;
-- actual compositor layout and tray behavior need a desktop runtime check.
local callbacks, commands
local function reset()
    callbacks, commands = {}, {}
    hl = {
        on = function(event, callback) callbacks[event] = callback end,
        dsp = { layout = function(message) return message end },
        dispatch = function(message) commands[#commands + 1] = message end,
    }
    dofile("home/de/hyprland/token-monitor-size.lua")
end

local function window(address, width, active)
    return {
        address = address, class = "token-monitor", active = active,
        floating = false, size = { x = 1700, y = 1000 },
        layout = { name = "scrolling", column = { width = width } },
    }
end

reset()
local first = window("old", 0.33, true)
callbacks["window.open"](first)
assert(#commands == 0, "first open must keep the layout's initial width")
callbacks["window.close"](first)
local reopened = window("new", 0.5, true)
callbacks["window.open"](reopened)
assert(commands[1] == "colresize 0.330000000", "restore logical width, not fullscreen pixels")
callbacks["window.active"](reopened)
assert(#commands == 1, "ordinary refocus must not undo subsequent manual resizing")

reopened.layout.column.width = 0.67
callbacks["window.close"](reopened)
local waiting = window("waiting", 0.5, false)
callbacks["window.open"](waiting)
assert(#commands == 1, "opening without focus must not resize another app")
local other = window("other", 0.9, true)
other.class = "foot"
callbacks["window.active"](other)
callbacks["window.active"](nil)
assert(#commands == 1, "unrelated focus and empty focus must be ignored")
waiting.active = true
callbacks["window.active"](waiting)
assert(commands[2] == "colresize 0.670000000", "restore once the reopened window gains focus")

local abandoned = window("abandoned", 0.5, false)
callbacks["window.open"](abandoned)
callbacks["window.close"](abandoned)
local final = window("final", 0.5, true)
callbacks["window.open"](final)
assert(commands[3] == "colresize 0.670000000", "an unfocused hide must not replace remembered width")

local floating = window("floating", 0.9, true)
floating.floating = true
callbacks["window.close"](floating)
callbacks["window.open"](floating)
other.layout.column.width = 0.9
callbacks["window.close"](other)
local later = window("later", 0.5, true)
callbacks["window.open"](later)
assert(commands[4] == "colresize 0.670000000", "floating and other apps must leave tiled memory unchanged")

reset()
callbacks["window.open"](window("after-reload", 0.5, true))
assert(#commands == 0, "config reload starts a fresh memory")
print("Token Monitor mocked event checks passed")
