{ config, ... }:
{
  system.defaults.dock = {
    persistent-apps = [
      "/Applications/Google Chrome.app"
      "/Applications/Nix Apps/Slack.app"
      "/Applications/Ghostty.app"
      # vscode can not be here as long as it is managed by home-manager. the path to it is too strange.
    ];
  };
}
