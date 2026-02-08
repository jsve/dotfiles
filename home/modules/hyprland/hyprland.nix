# Hyprland window manager configuration via home-manager
# Launched via start-hyprland which handles nixGL wrapping automatically
#
# Reference: https://gist.github.com/AntonFriberg/1dcb1ee6bf2c92c5f641a6f764d582d9
# Docs: https://wiki.hyprland.org/
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # hyprpolkitagent - Polkit authentication agent for Hyprland
  # Required for GUI applications to request elevated privileges (sudo dialogs).
  # Qt/QML app that needs nixGL wrapping on non-NixOS systems.
  # Reference: https://wiki.hypr.land/Hypr-Ecosystem/hyprpolkitagent/
  hyprpolkitagent = config.lib.nixGL.wrap pkgs.hyprpolkitagent;

  # Catppuccin Kvantum theme - Mocha with Pink accent to match Hyprland theme
  # Pink accent (#f5c6e7) matches our border colors and Walker theme
  catppuccin-kvantum-mocha-pink = pkgs.catppuccin-kvantum.override {
    accent = "pink";
    variant = "mocha";
  };

  # Catppuccin GTK theme - Mocha with Pink accent to match Qt/Kvantum theme
  catppuccin-gtk-mocha-pink = pkgs.catppuccin-gtk.override {
    accents = [ "pink" ];
    variant = "mocha";
  };
in
{
  # Install hyprpolkitagent and make its systemd service available
  home.packages = [
    hyprpolkitagent

    # Kvantum theme engine for Qt5/Qt6 with Catppuccin Mocha Pink
    pkgs.libsForQt5.qtstyleplugin-kvantum
    pkgs.qt6Packages.qtstyleplugin-kvantum
    catppuccin-kvantum-mocha-pink

    # GTK theme - Catppuccin Mocha Pink (Hyprland-only via env vars below)
    catppuccin-gtk-mocha-pink
  ];
  systemd.user.packages = [ hyprpolkitagent ];

  # GNOME Keyring - Secret Service for credential storage
  # Provides the D-Bus Secret Service API that apps like GitHub Desktop use.
  # This ensures credentials persist when switching between GNOME and Hyprland.
  # The keyring database is shared (~/.local/share/keyrings/).
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ]; # Only secrets - GNOME handles pkcs11/ssh when active
  };

  # Kvantum configuration - set Catppuccin Mocha Pink as the theme
  # This config file tells Kvantum which theme to use
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-mocha-pink
  '';

  wayland.windowManager.hyprland = {
    enable = true;

    # No nixGL wrapping needed — start-hyprland handles it automatically.
    # Since Hyprland 0.53.2, the start-hyprland watchdog binary:
    #   1. Detects that Hyprland was built with Nix on a non-NixOS system
    #   2. Calls execvp("nixGL", ...) to wrap Hyprland with the right GPU drivers
    #   3. Provides a watchdog that restarts Hyprland in safe-mode on crash
    # The "nixGL" wrapper script is provided via linux-common.nix (delegates to nixGLMesa).
    # GDM session entry must use start-hyprland (not Hyprland directly).
    # See: start/src/core/Instance.cpp and start/src/helpers/Nix.cpp in Hyprland repo
    package = pkgs.hyprland;

    # Hyprland configuration
    # See https://wiki.hyprland.org/Configuring/
    settings = {
      # Environment variables - Hyprland-session only (not GNOME)
      # Reference: https://wiki.hyprland.org/Configuring/Environment-variables/
      #
      # NOT needed here (auto-set by home-manager hyprland module via systemd):
      #   XDG_CURRENT_DESKTOP, XDG_SESSION_TYPE - see systemd.variables in
      #   github:nix-community/home-manager/modules/services/window-managers/hyprland.nix
      #
      # NOT needed (auto-detected by toolkits):
      #   GDK_BACKEND - GTK auto-detects Wayland via WAYLAND_DISPLAY
      #   SDL_VIDEODRIVER - leave default, setting can break some games
      env = [
        "QT_QPA_PLATFORM,wayland;xcb" # Use Wayland, fall back to X11
        "QT_AUTO_SCREEN_SCALE_FACTOR,1" # Automatic HiDPI scaling
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1" # Let Hyprland handle decorations

        # Qt theming - Kvantum with Catppuccin Mocha Pink (matches Hyprland theme)
        # Only set in Hyprland session; GNOME handles Qt theming automatically
        "QT_STYLE_OVERRIDE,kvantum"

        # GTK theming - Catppuccin Mocha Pink (Hyprland-only)
        # GTK_THEME overrides settings.ini, so this won't affect GNOME session
        "GTK_THEME,catppuccin-mocha-pink-standard"
      ];

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
        # X position = (external_width - laptop_width) / 2 = (2560 - 2048) / 2 = 256
        # Scale 1.25 for 2560x1600 @ 13.4" = 2048x1280 logical
        "eDP-1, 2560x1600@180, 256x1440, 1.25"

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
          natural_scroll = false; # Traditional scroll direction
          tap-to-click = false; # Disable tap, require physical click
          clickfinger_behavior = true; # 2 fingers + click = right click (instead of position-based)
          middle_button_emulation = false; # Disable middle click emulation
        };
        sensitivity = 0;
      };

      # Variables
      "$terminal" = "ghostty";
      "$menu" = "walker";
      "$mainMod" = "SUPER";

      # Autostart
      exec-once = [
        # Polkit agent for authentication dialogs (sudo prompts)
        "systemctl --user start hyprpolkitagent"

        # Status bar
        "waybar"
      ];

      # Layer rules for blur on transparent bars/menus
      # See https://wiki.hypr.land/Configuring/Window-Rules/#layer-rules
      layerrule = [
        "blur on, match:namespace waybar"
        "ignore_alpha 0.3, match:namespace waybar"
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

      # Gestures - Hyprland 0.53+ syntax
      # gesture = fingers, direction, action
      # direction: horizontal (left/right), vertical (up/down)
      # For workspace switching, use "horizontal" with the workspace action
      gesture = "3, horizontal, workspace";
    };
  };
}
