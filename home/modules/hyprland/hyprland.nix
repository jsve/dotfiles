# Hyprland window manager configuration via home-manager
# Uses nixGL wrapper for standalone (non-NixOS) systems
#
# Reference: https://gist.github.com/AntonFriberg/1dcb1ee6bf2c92c5f641a6f764d582d9
# Docs: https://wiki.hyprland.org/
{
  config,
  pkgs,
  lib,
  ...
}:
{
  wayland.windowManager.hyprland = {
    enable = true;

    # Wrap with nixGL for GPU access on non-NixOS (Fedora)
    # nixGL is configured in linux-common.nix with mesa wrapper for AMD GPU
    # Note: Since Hyprland 0.53.2, start-hyprland auto-detects nixGL for standalone installs,
    # but Home Manager doesn't use that script, so manual wrapping is still required.
    package = config.lib.nixGL.wrap pkgs.hyprland;

    # Hyprland configuration
    # See https://wiki.hyprland.org/Configuring/
    settings = {
      # Monitor configuration
      # See https://wiki.hyprland.org/Configuring/Monitors/
      # Layout: External monitors ABOVE laptop screen (vertically stacked)
      # Position format: XxY where higher Y = lower on screen
      monitor = [
        # Philips external monitor (by description for port flexibility)
        # Position 0x0 = top, scale 1.5 (4K at 1.5 = 2560x1440 logical)
        "desc:Philips Consumer Electronics Company PHL 279M1RV, 3840x2160@120, 0x0, 1.5"

        # Laptop screen below external monitor, centered horizontally
        # Y position = external's scaled height (2160/1.5 = 1440)
        # X position = (external_width - laptop_width) / 2 = (2560 - 1280) / 2 = 640
        "eDP-1, 2560x1600@180, 640x1440, 2"

        # Fallback for unknown external monitors - place above laptop
        ", preferred, 0x0, 1.5"
      ];

      # General appearance
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(f77ab0ee) rgba(f5c6e7ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      # Decoration (rounded corners, blur, etc)
      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Dwindle layout settings
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Input configuration
      input = {
        kb_layout = "se";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        };
        sensitivity = 0;
      };

      # Variables
      "$terminal" = "ghostty";
      "$menu" = "walker";
      "$mainMod" = "SUPER";

      # Autostart
      exec-once = [
        # Polkit agent for authentication dialogs
        # Note: Using systemd service instead of hyprpolkitagent for now
        # "systemctl --user start hyprpolkitagent"
      ];

      # Keybindings
      bind = [
        # Core
        "$mainMod, Q, exec, $terminal"
        "$mainMod, C, killactive"
        "$mainMod, M, exit"
        "$mainMod, E, exec, nautilus"
        "$mainMod, V, togglefloating"
        "$mainMod, SPACE, exec, $menu"
        "$mainMod, P, pseudo"
        "$mainMod, J, togglesplit"

        # Move focus
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Vim-style focus
        "$mainMod, H, movefocus, l"
        "$mainMod, L, movefocus, r"
        "$mainMod, K, movefocus, u"
        # "$mainMod, J, movefocus, d"  # Conflicts with togglesplit

        # Switch workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move window to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Special workspace (scratchpad)
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # Scroll through workspaces
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];

      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # Gestures - new syntax: gesture = fingers, direction, action, options
      # Swipe left/right to switch workspaces
      gesture = [
        "3, l, workspace, -1"
        "3, r, workspace, +1"
      ];
    };
  };
}
