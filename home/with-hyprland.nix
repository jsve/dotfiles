# Hyprland-specific home-manager configuration
# Import this for systems running Hyprland
#
# Installs via Nix + home-manager on standalone systems like Fedora
# Reference: https://gist.github.com/AntonFriberg/1dcb1ee6bf2c92c5f641a6f764d582d9
{ ... }:
{
  imports = [
    ./modules/hyprland/hyprland.nix
    ./modules/hyprland/walker.nix
  ];
}
