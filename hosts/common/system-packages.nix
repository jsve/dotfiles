# System-level packages installed via environment.systemPackages
# Used by both nix-darwin (macOS) and NixOS (Linux) configurations
# Imports the shared package list from system-packages-list.nix
# For user-level packages, see home/common.nix instead
{
  inputs,
  pkgs,
  unstablePkgs,
  ...
}:
let
  inherit (inputs) nixpkgs nixpkgs-unstable;
  # Import the shared package list - it's a function that takes pkgs and returns a list
  packageList = import ./system-packages-list.nix { inherit pkgs; };
in
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = packageList;
}
