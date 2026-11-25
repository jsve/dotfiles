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

  # Command-line packages live in ./core.nix. Desktop apps:
  # managed by homebrew
  # ghostty
  # steam

}
