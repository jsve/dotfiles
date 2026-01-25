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
  systemd.user.sessionVariables = lib.mkIf pkgs.stdenv.isLinux {
    PATH = "$HOME/.nix-profile/bin:$PATH";
  };

  # Install the shared package list at user-level
  home.packages = packageList ++ regularGuiPackages ++ openglGuiPackages;

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
