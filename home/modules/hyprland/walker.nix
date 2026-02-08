# Walker - Application launcher for Hyprland
# Uses elephant as the backend service
# Theme: ezerfrlux/omarchy-config pink accents style
# Docs: https://benz.gitbook.io/walker/
{ inputs, ... }:
{
  imports = [
    inputs.walker.homeManagerModules.default
  ];

  programs.walker = {
    enable = true;
    runAsService = true;

    # Walker config
    # See https://github.com/abenz1267/walker/blob/master/resources/config.toml
    config = {
      theme = "ezer";
      force_keyboard_focus = true;
      selection_wrap = true;
      hide_action_hints = true;

      providers.prefixes = [
        {
          provider = "providerlist";
          prefix = "/";
        }
        {
          provider = "files";
          prefix = ".";
        }
        {
          provider = "symbols";
          prefix = ":";
        }
        {
          provider = "calc";
          prefix = "=";
        }
        {
          provider = "websearch";
          prefix = "@";
        }
        {
          provider = "clipboard";
          prefix = "$";
        }
        {
          provider = "bluetooth";
          prefix = "!";
        }
      ];
    };

    # ezerfrlux-style pink accents theme
    themes = {
      "ezer" = {
        style = ''
          /* ezerfrlux/omarchy-config inspired theme */
          /* Colors: pink #f77ab0 selected, #f5c6e7 text, #2b2e34 background */

          @define-color window_bg_color #2b2e34;
          @define-color accent_bg_color #f77ab0;
          @define-color theme_fg_color #f5c6e7;
          @define-color error_bg_color #C34043;
          @define-color error_fg_color #f5c6e7;

          * {
            all: unset;
          }

          popover {
            background: lighter(@window_bg_color);
            border: 1px solid @accent_bg_color;
            border-radius: 18px;
            padding: 10px;
          }

          .normal-icons {
            -gtk-icon-size: 16px;
          }

          .large-icons {
            -gtk-icon-size: 32px;
          }

          scrollbar {
            opacity: 0;
          }

          .box-wrapper {
            box-shadow:
              0 19px 38px rgba(0, 0, 0, 0.3),
              0 15px 12px rgba(0, 0, 0, 0.22);
            background: @window_bg_color;
            padding: 20px;
            border-radius: 20px;
            border: 1px solid @theme_fg_color;
          }

          .preview-box,
          .elephant-hint,
          .placeholder {
            color: @theme_fg_color;
          }

          .box {
          }

          .search-container {
            border-radius: 10px;
          }

          .input placeholder {
            opacity: 0.5;
          }

          .input selection {
            background: @accent_bg_color;
          }

          .input {
            caret-color: @accent_bg_color;
            background: lighter(@window_bg_color);
            padding: 10px;
            color: @theme_fg_color;
          }

          .input:focus,
          .input:active {
          }

          .content-container {
          }

          .placeholder {
          }

          .scroll {
          }

          .list {
            color: @theme_fg_color;
          }

          child {
          }

          .item-box {
            border-radius: 10px;
            padding: 10px;
          }

          .item-quick-activation {
            background: alpha(@accent_bg_color, 0.25);
            border-radius: 5px;
            padding: 10px;
          }

          child:selected .item-box {
            background: alpha(@accent_bg_color, 0.35);
          }

          child:selected .item-text {
            color: @accent_bg_color;
          }

          .item-text-box {
          }

          .item-subtext {
            font-size: 12px;
            opacity: 0.5;
          }

          .providerlist .item-subtext {
            font-size: unset;
            opacity: 0.75;
          }

          .item-image-text {
            font-size: 28px;
          }

          .preview {
            border: 1px solid alpha(@accent_bg_color, 0.25);
            border-radius: 10px;
            color: @theme_fg_color;
          }

          .calc .item-text {
            font-size: 24px;
          }

          .calc .item-subtext {
          }

          .symbols .item-image {
            font-size: 24px;
          }

          .todo.done .item-text-box {
            opacity: 0.25;
          }

          .todo.urgent {
            font-size: 24px;
          }

          .todo.active {
            font-weight: bold;
          }

          .bluetooth.disconnected {
            opacity: 0.5;
          }

          .preview .large-icons {
            -gtk-icon-size: 64px;
          }

          .keybinds {
            padding-top: 10px;
            border-top: 1px solid lighter(@window_bg_color);
            font-size: 12px;
            color: @theme_fg_color;
          }

          .global-keybinds {
          }

          .item-keybinds {
          }

          .keybind {
          }

          .keybind-button {
            opacity: 0.5;
          }

          .keybind-button:hover {
            opacity: 0.75;
          }

          .keybind-bind {
            text-transform: lowercase;
            opacity: 0.35;
          }

          .keybind-label {
            padding: 2px 4px;
            border-radius: 4px;
            border: 1px solid @theme_fg_color;
          }

          .error {
            padding: 10px;
            background: @error_bg_color;
            color: @error_fg_color;
          }

          :not(.calc).current {
            font-style: italic;
          }

          .preview-content.archlinuxpkgs, .preview-content.dnfpackages {
            font-family: monospace;
          }
        '';
      };
    };

    # Elephant backend settings
    elephant = {
      settings = {
        auto_detect_launch_prefix = true;
      };
      providers = [
        "desktopapplications"
        "calc"
        "clipboard"
        "files"
        "runner"
        "symbols"
        "websearch"
        "bluetooth"
        "providerlist"
      ];
      provider = {
        # Symbols/emoji provider - type directly instead of copy to clipboard
        symbols.settings.command = "wtype %VALUE%";
      };
    };
  };
}
