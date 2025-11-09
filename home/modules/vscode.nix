{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;

    profiles.default = {
      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;

      # Extensions
      extensions = (with pkgs.vscode-marketplace-release; [
        esbenp.prettier-vscode
        github.copilot
        github.copilot-chat
      ]);

      userSettings = {
        # IDE
        # "files.trimTrailingWhitespace" = true;
        "editor.formatOnSave" = true;
        # "explorer.confirmDragAndDrop" = false;

        # # Misc
        # "[nix]"."editor.tabSize" = 2;
        # "yaml.format.enable" = false;
        # "[markdown]"."files.trimTrailingWhitespace" = false;
        # "[env]"."editor.formatOnSave" = false;
      };
    };
  };
}