# Linux-specific home-manager configuration for standalone (non-NixOS) systems like Fedora
# On standalone home-manager, there's no system-level package management (no environment.systemPackages)
# So we import the shared package list and add it to user-level home.packages instead
{ pkgs, lib, ... }:
let
  # Import the shared package list from hosts/common - same packages as nix-darwin/NixOS system packages
  # but installed at user-level since we don't have system-level package management on Fedora
  packageList = import ./../hosts/common/system-packages-list.nix { inherit pkgs; };
in
{
  # Make packages available system-wide via systemd user session
  # Required because standalone home-manager doesn't auto-configure PATH like nix-darwin does
  systemd.user.sessionVariables = lib.mkIf pkgs.stdenv.isLinux {
    PATH = "$HOME/.nix-profile/bin:$PATH";
  };

  # Install the shared package list at user-level
  home.packages = packageList;

  # Set zsh as default shell on Fedora
  # Reference: https://wiki.nixos.org/wiki/Command_Shell#Changing_the_default_shell
  home.activation.setDefaultShell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    zsh_path="${pkgs.zsh}/bin/zsh"
    current_shell=$(getent passwd "$USER" | cut -d: -f7)

    if [ "$current_shell" != "$zsh_path" ]; then
      # First ensure zsh is in /etc/shells
      if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
        $DRY_RUN_CMD echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null || {
          echo "Failed to add zsh to /etc/shells. Run manually: echo $zsh_path | sudo tee -a /etc/shells" >&2
          exit 1
        }
      fi
      
      # Change the default shell
      $DRY_RUN_CMD chsh -s "$zsh_path" || {
        echo "Failed to change default shell. Run manually: chsh -s $zsh_path" >&2
        exit 1
      }
      
      echo "Default shell changed to zsh. Please log out and back in."
    fi
  '';
}
