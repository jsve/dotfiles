# Hyprland-specific home-manager configuration
# Import this for systems running Hyprland
{ ... }:
{
  imports = [
    ./modules/hyprland/walker.nix
  ];
}
