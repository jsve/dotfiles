{ pkgs, lib, ... }:
{
    home.stateVersion = "25.05";

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    imports = [
      "./modules/vscode.nix"
    ];

    home.packages = with pkgs; [
      # Haxx
      bruno
      gh
      neovim
      openssl
      opencode
      orbstack
      # ghostty <- managed by homebrew

      # Entertainment
      # steam <- managed by homebrew

      # Communication
      # slack
    ];

}