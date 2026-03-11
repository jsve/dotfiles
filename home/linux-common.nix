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
  # Enable generic Linux target for better integration on non-NixOS (Fedora)
  targets.genericLinux.enable = true;

  # Configure nixGL for GPU access (OpenGL/Vulkan wrappers)
  # Required for GUI apps to access GPU on non-NixOS systems
  targets.genericLinux.nixGL = {
    packages = nixGL.packages;
    defaultWrapper = "mesa"; # AMD GPU (Radeon) - use "nvidia" for NVIDIA
    installScripts = [ "mesa" ]; # Installs nixGLMesa script in PATH
  };

  # Configure environment variables for systemd user session and all user processes
  #
  # This sets variables via environment.d, which is read by:
  # - systemd user services (via systemd --user)
  # - GNOME Shell and other desktop environments (via pam_systemd at login)
  # - All processes started from the graphical session
  #
  # HOME-MANAGER IMPLEMENTATION NOTE:
  # systemd.user.sessionVariables automatically creates ~/.config/environment.d/10-home-manager.conf
  # which is processed by systemd-environment-d-generator at login time.
  #
  # WHY WE NEED PATH:
  # Required for standalone home-manager (doesn't auto-configure like nix-darwin).
  # Without this, Nix packages in ~/.nix-profile/bin won't be accessible from GUI apps.
  #
  # NOTE: XDG_DATA_DIRS is now handled by targets.genericLinux.enable = true
  # which sets it via xdg.systemDirs.data (including nix profile paths).
  #
  # REFERENCES:
  # - /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh lines 34-39 (Nix's own solution for shells)
  # - XDG Base Directory Specification: https://specifications.freedesktop.org/basedir-spec/latest/
  # - systemd environment.d: man systemd-environment-d-generator(8)
  systemd.user.sessionVariables = lib.mkIf pkgs.stdenv.isLinux {
    PATH = "$HOME/.nix-profile/bin:$PATH";
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

  # Fonts — mirrors fonts.packages in darwin-system.nix
  # On non-NixOS, there's no fonts.packages so we install via home.packages
  # and enable fontconfig so fc-cache picks them up
  fonts.fontconfig.enable = true;

  # Install the shared package list at user-level
  home.packages =
    packageList
    ++ regularGuiPackages
    ++ openglGuiPackages
    ++ [
      pkgs.nerd-fonts.jetbrains-mono

      # "nixGL" binary — required by start-hyprland (Hyprland 0.53.2+)
      #
      # start-hyprland calls execvp("nixGL", ...) to wrap Hyprland with GPU drivers.
      # See: https://github.com/hyprwm/Hyprland/blob/main/start/src/core/Instance.cpp
      #
      # Problem: The nixGL flake only exports specifically-named binaries (nixGLIntel,
      # nixGLMesa, etc.) but not a generic "nixGL". The auto-detecting nixGLDefault
      # requires --impure for nvidia detection.
      #
      # Solution: Copy the mesa wrapper binary and rename it to "nixGL".
      # This mirrors what nixGLCommon does internally in the nixGL flake.
      # For NVIDIA, change nixGLIntel to nixGL.packages.${system}.nixGLNvidia
      #
      # Check if still needed: grep 'execvp.*nixGL' in Hyprland's start/ directory
      # Versions: Hyprland 0.53.3, home-manager nixGL PR #5355 (Oct 2024)
      # See: hosts/linux/JsFlowdora/fedora-setup.md for full explanation
      (pkgs.runCommand "nixGL" { } ''
        mkdir -p $out/bin
        cp ${nixGL.packages.${pkgs.system}.nixGLIntel}/bin/* $out/bin/nixGL
      '')
    ]
    ++ (with pkgs; [
      lm_sensors # Temperature sensor readings (Linux-only)
      # Fun ASCII/terminal toys (JsFlowdora only for now)
      cowsay
      sl
      cmatrix
      asciiquarium
    ]);

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
