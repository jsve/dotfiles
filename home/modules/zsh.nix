{ pkgs, config, ... }:
{
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    autosuggestion = {
      enable = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "history"
        "git"
        "github"
        "colorize"
        "kube-ps1"
        "kubectl"
        "docker"
      ];
      custom = "$HOME/.oh-my-custom";
    };

    plugins = [
      {
        name = "nix-shell";
        file = "nix-shell.plugin.zsh";
        src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell";
      }
    ];
  };
}