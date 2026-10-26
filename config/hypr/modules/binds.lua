-- BINDS
local terminal = "kitty"
local browser = "firefox"
local launcher = "quickshell ipc -c fortress call fortress launcherToggle"
local rofi = "rofi -show drun"

-- open programs
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + F", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + Tab", hl.dsp.global("quickshell:overview"))
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind("SUPER + N", hl.dsp.global("quickshell:notes"))
hl.bind("SUPER + D", hl.dsp.exec_cmd(rofi))
hl.bind("SUPER + W", function()
	hl.exec_cmd("python3 /home/lenz/.config/hypr/sync-theme.py --apply")
end)
hl.bind("SUPER + B", function()
	hl.exec_cmd("zen-browser")
end)

hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | wl-copy'), {
	description = "Screenshot Bereich in Zwischenablage",
})

-- volume/brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })

hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- hyprland binds
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + M", hl.dsp.exit())

for i = 1, 9 do
	hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
	hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- move focus
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }))

-- move window
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
