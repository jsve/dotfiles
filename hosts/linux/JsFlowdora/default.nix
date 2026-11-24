# JsFlowdora host-specific configuration
{ lib, pkgs, ... }:
{
  imports = [
    ../../../home/with-hyprland.nix
  ];

  # ROCm build of btop for proper iGPU stats; hiPrio wins over the shared plain btop.
  home.packages = [
    (lib.hiPrio pkgs.btop-rocm)
  ];
}
