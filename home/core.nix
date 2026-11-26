# Shell setup and command-line tools shared by every machine, including the
# clanker-box VMs (hosts/vms/clanker-boxes), which import this file but not common.nix.
# Keep desktop-only and personal things (GUI apps, editors' settings, identities,
# anything secret) out of here: whatever is listed lands in the agent VMs too.
{ pkgs, ... }:
{
  imports = [
    ./modules/zsh.nix
    ./modules/direnv.nix
  ];

  home.packages = with pkgs; [
    # Haxx
    # bruno # installs it's own version of node. don't use it for now.
    gh
    neovim
    openssl

    # ch:
    nodejs_26
    python313
    # yarn # installs it's own version of node. don't use it for now.
  ];
}
