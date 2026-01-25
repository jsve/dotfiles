# Linux-specific home-manager configuration for standalone (non-NixOS) systems like Fedora
# On standalone home-manager, there's no system-level package management (no environment.systemPackages)
# So we import the shared package list and add it to user-level home.packages instead
{
  pkgs,
  lib,
  config,
  nixGL,
  ...
}:
let
  # Import the shared package list from hosts/common - same packages as nix-darwin/NixOS system packages
  # but installed at user-level since we don't have system-level package management on Fedora
  packageList = import ./../hosts/common/system-packages-list.nix { inherit pkgs; };

  # Import GUI apps manifest
  guiApps = import ./../hosts/common/gui-apps-list.nix;

  # Apps that need OpenGL wrapping
  openglApps = guiApps.linux-opengl-apps;

  # Regular GUI apps (non-OpenGL)
  regularAppsNames = builtins.filter (appName: !(builtins.elem appName openglApps)) (
    guiApps.common ++ guiApps.linux
  );

  # Map regular app names to nix packages where available
  regularGuiPackages = builtins.filter (x: x != null) (
    builtins.map (
      appName: if builtins.hasAttr appName pkgs then pkgs.${appName} else null
    ) regularAppsNames
  );

  # Map OpenGL app names to wrapped packages
  openglGuiPackages = builtins.filter (x: x != null) (
    builtins.map (
      appName: if builtins.hasAttr appName pkgs then config.lib.nixGL.wrap pkgs.${appName} else null
    ) openglApps
  );
in
{
  # Configure nixGL
  targets.genericLinux.nixGL = {
    packages = nixGL.packages;
    defaultWrapper = "mesa"; # Use mesa for most systems, change to "nvidia" if using NVIDIA GPU
  };

  # Make packages available system-wide via systemd user session
  # Required because standalone home-manager doesn't auto-configure PATH like nix-darwin does
  #
  # CRITICAL: Also set XDG_DATA_DIRS so GNOME can find desktop entries and icons.
  # The Nix installer's nix-daemon.sh script sets this for shell sessions, but systemd
  # user services (and GNOME Shell itself) don't source shell profiles, so they miss
  # the Nix paths. Without this, desktop entries in ~/.nix-profile/share/applications/
  # won't appear in GNOME's app launcher.
  #
  # Reference: /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh lines 34-39
  # Reference: XDG Base Directory Specification (freedesktop.org)
  systemd.user.sessionVariables = lib.mkIf pkgs.stdenv.isLinux {
    PATH = "$HOME/.nix-profile/bin:$PATH";
    XDG_DATA_DIRS = "$HOME/.nix-profile/share:/nix/var/nix/profiles/default/share:$XDG_DATA_DIRS";
  };

  # Enable systemd services from packages (home-manager PR #8540)
  # This makes D-Bus activation work properly for GUI apps.
  #
  # Without this, apps with DBusActivatable=true in their .desktop files (like Ghostty)
  # would fail to launch from the GNOME app launcher with the error:
  #   "Activation request for 'com.example.app' failed: 
  #    The systemd unit 'app-com.example.app.service' could not be found."
  #
  # The issue occurs because:
  # - The app works fine when launched from terminal (direct binary execution)
  # - But fails from GNOME app launcher (uses D-Bus activation via systemd)
  # - systemd doesn't search ~/.nix-profile/share/systemd/user/ for service files
  # - This option symlinks services to ~/.local/share/systemd/user/ where systemd looks
  #
  # Debug commands:
  #   journalctl --user -n 200 | grep -i "app-name"
  #   systemctl --user status app-com.example.app.service
  systemd.user.packages = openglGuiPackages ++ regularGuiPackages;

  # Install the shared package list at user-level
  home.packages = packageList ++ regularGuiPackages ++ openglGuiPackages ++ (with pkgs; [
    # Fun ASCII/terminal toys (JsFlowdora only for now)
    cowsay
    sl
    cmatrix
    asciiquarium
  ]);

  # Ensure GNOME/systemd user session has correct environment variables for Nix packages
  # 
  # This config file is read by systemd --user and pam_systemd at login time.
  # It ensures that all user sessions (including graphical sessions like GNOME)
  # have access to Nix packages and their XDG data (desktop entries, icons, etc.)
  #
  # Why both systemd.user.sessionVariables AND environment.d?
  # - systemd.user.sessionVariables: Sets variables for systemd user services
  # - environment.d: Sets variables for the entire user session (including login shells)
  # Both are needed to ensure consistency across all contexts.
  #
  # Without XDG_DATA_DIRS here:
  # - Terminal sessions work (they source /etc/profile.d/nix.sh)
  # - GNOME Shell doesn't (it starts from GDM, not a shell)
  # - Result: Desktop entries missing from GNOME app launcher after reboot
  xdg.configFile."environment.d/envvars.conf".text = ''
    PATH="$HOME/.nix-profile/bin:$PATH"
    XDG_DATA_DIRS="$HOME/.nix-profile/share:/nix/var/nix/profiles/default/share:$XDG_DATA_DIRS"
  '';

  # Check if zsh is the default shell and inform user how to set it up
  # Reference: https://wiki.nixos.org/wiki/Command_Shell#Changing_the_default_shell
  home.activation.checkDefaultShell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    zsh_path="${pkgs.zsh}/bin/zsh"
    if [ "$SHELL" != "$zsh_path" ]; then
      echo ""
      echo "ℹ️  Zsh is not your default shell yet."
      echo "   Run: just setup-shell"
      echo ""
    fi
  '';
}
