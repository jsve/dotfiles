{
  inputs,
  pkgs,
  unstablePkgs,
  ...
}:
let
  inherit (inputs) nixpkgs nixpkgs-unstable;
in
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
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
  ];
}
