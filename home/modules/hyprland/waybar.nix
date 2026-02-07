# Waybar - Status bar for Hyprland
# Styled to match the pink accent theme (Walker, Hyprland borders, etc.)
#
# Installation approach for non-NixOS (Fedora):
# - programs.waybar.enable installs waybar via home.packages
# - We override the package with nixGL wrapping for GPU access
# - Waybar is autostarted via Hyprland exec-once
# - systemd service is NOT used (Hyprland manages the lifecycle)
#
# Docs: https://github.com/Alexays/Waybar/wiki/Configuration
# Hyprland modules: https://github.com/Alexays/Waybar/wiki/Module:-Hyprland
# Styling: https://github.com/Alexays/Waybar/wiki/Styling
{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.waybar = {
    enable = true;

    # Wrap with nixGL for GPU/GTK access on non-NixOS (Fedora)
    # Same pattern as Hyprland wrapping in hyprland.nix
    package = config.lib.nixGL.wrap pkgs.waybar;

    # Don't use systemd service - Hyprland manages waybar lifecycle via exec-once
    # (systemd.enable = true would create a service tied to graphical-session.target,
    # but on non-NixOS with Hyprland we want tighter control)
    systemd.enable = false;

    # ── Layout: "Floating pills" style ──────────────────────────────────────
    # Modules are grouped into pill-shaped containers via CSS.
    # Left:   workspaces
    # Center: window title
    # Right:  system tray | network | cpu/memory | battery | clock
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        margin-top = 6;
        margin-left = 10;
        margin-right = 10;
        spacing = 4;

        modules-left = [
          "hyprland/workspaces"
        ];

        modules-center = [
          "hyprland/window"
        ];

        modules-right = [
          "tray"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "battery"
          "clock"
        ];

        # ── Module configs ────────────────────────────────────────────────

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "󰎤";
            "2" = "󰎧";
            "3" = "󰎪";
            "4" = "󰎭";
            "5" = "󰎱";
            "6" = "󰎳";
            "7" = "󰎶";
            "8" = "󰎹";
            "9" = "󰎼";
            "10" = "󰽽";
            active = "󰮯";
            default = "󰊠";
            empty = "󰑊";
          };
          persistent-workspaces = {
            "*" = 5;
          };
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
          separate-outputs = true;
          icon = true;
          icon-size = 18;
          rewrite = {
            "(.*) — Mozilla Firefox" = "🌎 $1";
            "(.*) - Ghostty" = " $1";
            "(.*) - Visual Studio Code" = "󰨞 $1";
          };
        };

        clock = {
          format = " {:%H:%M}";
          format-alt = " {:%A, %d %B %Y  %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        cpu = {
          format = " {usage}%";
          tooltip = true;
          interval = 2;
        };

        memory = {
          format = " {}%";
          interval = 2;
        };

        battery = {
          states = {
            good = 95;
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
        };

        network = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀 {ipaddr}/{cidr}";
          format-disconnected = "󰤭 ";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}\n{essid} ({signalStrength}%)";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "󰂯 {volume}%";
          format-muted = "󰝟 ";
          format-icons = {
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right = "pavucontrol";
        };

        tray = {
          icon-size = 16;
          spacing = 8;
        };
      };
    };

    # ── CSS styling ─────────────────────────────────────────────────────────
    # "Floating pills" theme with pink accents matching Walker/Hyprland
    # Colors: #f77ab0 (pink accent), #f5c6e7 (light pink text), #2b2e34 (dark bg)
    style = ''
      /* ── Global ────────────────────────────────────────────────────────── */
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", "Symbols Nerd Font", monospace;
        font-size: 13px;
        min-height: 0;
      }

      /* ── Bar window ────────────────────────────────────────────────────── */
      window#waybar {
        background: transparent;
        color: #f5c6e7;
      }

      /* ── Tooltip ───────────────────────────────────────────────────────── */
      tooltip {
        background: #2b2e34;
        border: 1px solid #f77ab0;
        border-radius: 10px;
      }
      tooltip label {
        color: #f5c6e7;
      }

      /* ── Module pills ──────────────────────────────────────────────────── */
      /* Each module gets a dark pill-shaped background */
      #workspaces,
      #window,
      #tray,
      #pulseaudio,
      #network,
      #cpu,
      #memory,
      #battery,
      #clock {
        background: #2b2e34;
        padding: 0 14px;
        margin: 4px 3px;
        border-radius: 12px;
        border: 1px solid rgba(245, 198, 231, 0.15);
      }

      /* ── Workspaces ────────────────────────────────────────────────────── */
      #workspaces {
        padding: 0 6px;
      }

      #workspaces button {
        padding: 0 6px;
        color: rgba(245, 198, 231, 0.4);
        background: transparent;
        border-radius: 8px;
        margin: 4px 2px;
        transition: all 0.2s ease;
      }

      #workspaces button:hover {
        color: #f5c6e7;
        background: rgba(247, 122, 176, 0.15);
      }

      #workspaces button.empty {
        color: rgba(245, 198, 231, 0.2);
      }

      #workspaces button.visible {
        color: #f5c6e7;
        background: rgba(247, 122, 176, 0.2);
      }

      #workspaces button.active {
        color: #2b2e34;
        background: linear-gradient(135deg, #f77ab0, #f5c6e7);
        font-weight: bold;
        border-radius: 8px;
      }

      #workspaces button.urgent {
        color: #2b2e34;
        background: #f7768e;
      }

      /* ── Window title ──────────────────────────────────────────────────── */
      #window {
        font-weight: bold;
        font-size: 12px;
      }

      /* Hide when empty (no focused window) */
      window#waybar.empty #window {
        background: transparent;
        border-color: transparent;
        padding: 0;
        margin: 0;
      }

      /* ── Clock ─────────────────────────────────────────────────────────── */
      #clock {
        color: #f77ab0;
        font-weight: bold;
      }

      /* ── Battery ───────────────────────────────────────────────────────── */
      #battery {
        color: #9ece6a;
      }

      #battery.warning {
        color: #e0af68;
      }

      #battery.critical {
        color: #f7768e;
        animation-name: blink;
        animation-duration: 1s;
        animation-timing-function: steps(12);
        animation-iteration-count: infinite;
        animation-direction: alternate;
      }

      @keyframes blink {
        to {
          color: #2b2e34;
          background-color: #f7768e;
        }
      }

      #battery.charging {
        color: #9ece6a;
      }

      /* ── Network ───────────────────────────────────────────────────────── */
      #network {
        color: #7aa2f7;
      }

      #network.disconnected {
        color: #f7768e;
      }

      /* ── Pulseaudio ────────────────────────────────────────────────────── */
      #pulseaudio {
        color: #bb9af7;
      }

      #pulseaudio.muted {
        color: rgba(245, 198, 231, 0.3);
      }

      /* ── CPU & Memory ──────────────────────────────────────────────────── */
      #cpu {
        color: #e0af68;
      }

      #memory {
        color: #7dcfff;
      }

      /* ── Tray ──────────────────────────────────────────────────────────── */
      #tray {
        padding: 0 8px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }
    '';
  };
}
