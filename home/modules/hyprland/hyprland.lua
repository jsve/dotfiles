-- Hyprland configuration (Lua).
-- Deployed to ~/.config/hypr/config.lua and loaded from the home-manager generated
-- ~/.config/hypr/hyprland.lua (see extraLuaFiles in hyprland.nix).
-- Hyprland >= 0.57 only reads Lua; hyprland.conf is ignored.
-- Reference: https://wiki.hypr.land/configuring/

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Hyprland-session only (not GNOME).
-- See https://wiki.hypr.land/configuring/core/environment-variables/
--
-- NOT needed here (auto-set by home-manager hyprland module via systemd):
--   XDG_CURRENT_DESKTOP, XDG_SESSION_TYPE - see systemd.variables in
--   github:nix-community/home-manager/modules/services/window-managers/hyprland
--
-- NOT needed (auto-detected by toolkits):
--   GDK_BACKEND - GTK auto-detects Wayland via WAYLAND_DISPLAY
--   SDL_VIDEODRIVER - leave default, setting can break some games
hl.env("QT_QPA_PLATFORM", "wayland;xcb") -- Use Wayland, fall back to X11
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1") -- Automatic HiDPI scaling
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1") -- Let Hyprland handle decorations

-- Qt theming - Kvantum with Catppuccin Mocha Pink (matches Hyprland theme)
-- Only set in Hyprland session; GNOME handles Qt theming automatically
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- GTK theming - Catppuccin Mocha Pink (Hyprland-only)
-- GTK_THEME overrides settings.ini, so this won't affect GNOME session
hl.env("GTK_THEME", "catppuccin-mocha-pink-standard")

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
-- Layout: External monitors ABOVE laptop screen (vertically stacked)
-- Position format: XxY where higher Y = lower on screen

-- Philips external monitor (by description for port flexibility)
-- Position 0x0 = top, scale 1.5 (4K at 1.5 = 2560x1440 logical)
hl.monitor({
    output   = "desc:Philips Consumer Electronics Company PHL 279M1RV",
    mode     = "3840x2160@120",
    position = "0x0",
    scale    = "1.5",
})

-- Laptop screen below external monitor, centered horizontally
-- Y position = external's scaled height (2160/1.5 = 1440)
-- X position = (external_width - laptop_width) / 2 = (2560 - 2048) / 2 = 256
-- Scale 1.25 for 2560x1600 @ 13.4" = 2048x1280 logical
hl.monitor({
    output   = "eDP-1",
    mode     = "2560x1600@180",
    position = "256x1440",
    scale    = "1.25",
})

-- Fallback for unknown external monitors - place above laptop
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "0x0",
    scale    = "1.5",
})

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- See https://wiki.hypr.land/configuring/core/config-options/
hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(f77ab0ee)", "rgba(f5c6e7ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        blur = {
            enabled = true,
            size    = 3,
            passes  = 1,
        },
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },
    },

    animations = {
        enabled = true,
    },

    -- dwindle:pseudotile no longer exists in Hyprland 0.57; pseudo is per-window (SUPER + P).
    dwindle = {
        preserve_split = true,
    },

    input = {
        kb_layout    = "se",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = {
            natural_scroll          = false, -- Traditional scroll direction
            tap_to_click            = false, -- Disable tap, require physical click
            clickfinger_behavior    = true, -- 2 fingers + click = right click (instead of position-based)
            middle_button_emulation = false, -- Disable middle click emulation
        },
    },
})

-- See https://wiki.hypr.land/configuring/core/animations/
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })

-- 3-finger horizontal swipe switches workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/
hl.on("hyprland.start", function()
    -- Polkit agent for authentication dialogs (sudo prompts)
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- Status bar
    hl.exec_cmd("waybar")
end)

---------------
---- RULES ----
---------------

-- Layer rules for blur on transparent bars/menus
-- See https://wiki.hypr.land/configuring/core/rules/
hl.layer_rule({
    name  = "waybar-blur",
    match = { namespace = "waybar" },

    blur         = true,
    ignore_alpha = 0.3,
})

---------------------
---- KEYBINDINGS ----
---------------------

-- See https://wiki.hypr.land/configuring/core/binds/
local terminal = "ghostty"
local menu     = "walker"
local mainMod  = "SUPER"

-- Core
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only

-- Lock screen
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("hyprlock"))

-- Move focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Vim-style focus (J is taken by togglesplit, so there is no "down")
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Function keys (media controls, volume, brightness)
-- locked = works even when the screen is locked; repeating = repeats while held

-- Volume and brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"),                            { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"),                            { locked = true, repeating = true })

-- Mute
hl.bind("XF86AudioMute",    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),   { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Media controls
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
