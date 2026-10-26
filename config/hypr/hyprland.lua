require("modules.ui-environment")
require("modules.binds")

-- Use the same persisted desktop scale as Quickshell Settings.
local guiScale = dofile(os.getenv("HOME") .. "/.config/hypr/modules/gui-scale.lua")
-- 175% needs fractional logical pixels; keep strict checks for other presets.
hl.config({ debug = { disable_scale_checks = guiScale == 1.75 } })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = guiScale })

hl.config({
	input = {
		kb_layout = "de",
	},
	general = {
		layout = "dwindle",
		gaps_out = 1,
		border_size = 3,
		col = {
			active_border = "rgba(f5895cdd)",
			inactive_border = "rgba(f5895c66)",
		},
	},
	decoration = {
		rounding = 12,
	},
})

-- Overview animates itself; avoid a second compositor fade after it closes.
hl.layer_rule({
    match = { namespace = "^fortress-overview$" },
    no_anim = true,
})

-- Keep numbered workspaces on a split layout, including existing workspaces.
for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), layout = "dwindle" })
end

-- New terminals should join the tiling layout at normal size.
hl.window_rule({
    match = { class = "kitty" },
    tile = true,
    fullscreen = false,
    maximize = false,
    suppress_event = "maximize",
})

hl.on("hyprland.start", function()
	hl.exec_cmd("python3 /home/lenz/.config/hypr/scripts/apply-ui-settings.py")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("quickshell -n -c fortress")
end)

monitor = {
    "eDP-1,preferred,0x0,1",
    "HDMI-A-1,preferred,1920x0,1",
}
bind = {
    "SUPER SHIFT, RIGHT, movewindow, r",
    "SUPER SHIFT, LEFT, movewindow, l",
}
