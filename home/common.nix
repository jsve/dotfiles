{ pkgs, lib, ... }:
{
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  imports = [
    ./modules/vscode.nix
    ./modules/zsh.nix
    ./modules/direnv.nix
  ];

  home.packages = with pkgs; [
    # Haxx
    # bruno # installs it's own version of node. don't use it for now.
    gh
    neovim
    openssl
    opencode

    # ch:
    nodejs_20
    python310
    pnpm_8
    # yarn # installs it's own version of node. don't use it for now.
    # pnpm_8 # installs it's own version of node. don't use it for now.

    # managed by homebrew
    # ghostty
    # steam
  ];

}
