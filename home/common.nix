{ pkgs, lib, ... }:
{
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  imports = [
    ./core.nix # shell setup and command-line tools, shared with the clanker-box VMs
    ./modules/vscode.nix
  ];

  systemd.user.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    PATH = "$HOME/.nix-profile/bin:$PATH";
  };

  # Packages for my own machines only. Tools the clanker-box VMs should also have
  # go in ./core.nix instead.
  home.packages = with pkgs; [
    opencode

    # managed by homebrew
    # ghostty
    # steam
  ];

}
