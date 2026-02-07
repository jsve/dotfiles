# Shared package list used across different configuration contexts:
# - On nix-darwin/NixOS: imported by system-packages.nix → environment.systemPackages (system-level)
# - On standalone home-manager (Fedora): imported by linux-common.nix → home.packages (user-level)
#
# This function takes pkgs as input and returns a list of packages
{ pkgs }:

with pkgs;
[
  ## stable
  # act
  # ansible
  # btop
  coreutils # GNU core utils
  # diffr # Modern Unix `diff`
  # difftastic # Modern Unix `diff`
  # drill
  # dust # Modern Unix `du`
  # dua # Modern Unix `du`
  # duf # Modern Unix `df`
  # direnv <- managed in home-manager
  # entr # Modern Unix `watch`
  # esptool
  # fastfetch
  # fd
  # ffmpeg
  # figurine
  # gh <- managed in home-manager
  # git-crypt
  # gnused
  # go
  # hugo
  # iperf3
  # ipmitool
  jq
  just
  # kubectl
  nixfmt # formatter for nix files
  # mc
  # mosh
  # nmap
  # nodejs <- conflicts with whatever is installed in home-manager
  # opencode <- managed in home-manager
  # qemu
  # ripgrep
  # skopeo
  # smartmontools
  # stow
  # television
  # terraform
  tree
  # unzip
  # watch
  # wget
  # wireguard-tools
  # uv
  zoxide

  # requires nixpkgs.config.allowUnfree = true;
  # vscode-extensions.ms-vscode-remote.remote-ssh
]
