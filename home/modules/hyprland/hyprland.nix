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

  # hyprlock - GPU-accelerated lock screen for Hyprland with custom Catppuccin styling
  # Two fixes needed for non-NixOS:
  # 1. PAM fix: Nix's linux-pam hardcodes /run/wrappers/bin/unix_chkpwd (NixOS-only).
  #    We patch it to use /usr/bin/unix_chkpwd (Fedora's location).
  #    See: https://github.com/nix-community/home-manager/issues/7027
  # 2. nixGL wrapping: hyprlock needs GPU access for rendering
  patchedPam = pkgs.linux-pam.overrideAttrs (old: {
    postPatch = ''
      substituteInPlace modules/module-meson.build \
        --replace-fail "sbindir / 'unix_chkpwd'" "'/usr/bin/unix_chkpwd'"
    '';
  });
  hyprlock = config.lib.nixGL.wrap (pkgs.hyprlock.override { pam = patchedPam; });

  # hypridle - Idle daemon for Hyprland that triggers lock/sleep on inactivity
  hypridle = pkgs.hypridle;

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
  # Install Hyprland ecosystem packages and theming
  home.packages = [
    hyprpolkitagent
    hypridle
    hyprlock

    # Kvantum theme engine for Qt5/Qt6 with Catppuccin Mocha Pink
    pkgs.libsForQt5.qtstyleplugin-kvantum
    pkgs.qt6Packages.qtstyleplugin-kvantum
    catppuccin-kvantum-mocha-pink

    # GTK theme - Catppuccin Mocha Pink (Hyprland-only via env vars below)
    catppuccin-gtk-mocha-pink

    # Media control utilities for function keys
    pkgs.brightnessctl # Screen brightness control
    pkgs.playerctl # Media player control (play/pause/next/prev)

    # Bluetooth manager (GTK GUI for bluez) - for advanced settings
    pkgs.blueman

    # Wayland text input tool - for typing emojis/symbols directly
    pkgs.wtype
  ];
  systemd.user.packages = [
    hyprpolkitagent
    hypridle
  ];

  # Start hypridle with Hyprland sessions only. hyprland-session.target is created by
  # home-manager's Hyprland module and started from inside Hyprland; binding to
  # graphical-session.target instead made hypridle start (and fail) under GNOME.
  systemd.user.services.hypridle = {
    Unit = {
      Description = "Hyprland idle daemon";
      After = [ "hyprland-session.target" ];
      PartOf = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${hypridle}/bin/hypridle";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
  };

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

  # hyprlock configuration - GPU-accelerated lock screen with Catppuccin Pink styling
  xdg.configFile."hypr/hyprlock.conf".source = ./hyprlock.conf;

  # hypridle configuration - Idle daemon for triggering lock/sleep on inactivity
  xdg.configFile."hypr/hypridle.conf".source = ./hypridle.conf;

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

    # Hyprland >= 0.57 only reads Lua (hyprland.conf is ignored), so generate
    # ~/.config/hypr/hyprland.lua. home-manager adds the systemd session hooks there
    # and requires our hand-written config, deployed as ~/.config/hypr/config.lua.
    configType = "lua";
    extraLuaFiles.config = ./hyprland.lua;
  };

  # Warn if /etc/pam.d/hyprlock is missing (required for authentication)
  home.activation.checkHyprlockPam = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f /etc/pam.d/hyprlock ]; then
      echo ""
      echo "WARNING: /etc/pam.d/hyprlock does not exist!"
      echo "hyprlock will not be able to authenticate without it."
      echo "Run: just setup-hyprlock"
      echo ""
    fi
  '';
}
