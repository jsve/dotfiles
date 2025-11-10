{ pkgs, lib, ... }:
{
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  imports = [
    ./modules/vscode.nix
    ./modules/zsh.nix
  ];

  home.packages = with pkgs; [
    # Haxx
    bruno
    gh
    neovim
    openssl
    opencode
    orbstack

    # ch:
    nodejs_20
    python310
    yarn
    pnpm_8

    # managed by homebrew
    # ghostty
    # steam
  ];

}
