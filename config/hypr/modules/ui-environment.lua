-- Read the same simple KEY=value file used by systemd's environment generator.
-- Keep toolkit values in one place; no global GTK_THEME/QT_STYLE_OVERRIDE.
local path = os.getenv("HOME") .. "/.config/environment.d/60-fortress-ui.conf"
for line in io.lines(path) do
    local key, value = line:match("^([%w_]+)=(.*)$")
    if key then hl.env(key, value) end
end
