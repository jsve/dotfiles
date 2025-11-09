{ config, ... }:
{
  system.defaults.dock = {
    persistent-apps = [
      "/Applications/Google Chrome.app"
      "/Applications/Slack.app"
      # "/Applications/Obsidian.app"
      "/Applications/Visual Studio Code.app"
      "/Applications/Ghostty.app"
    ];
  };
}