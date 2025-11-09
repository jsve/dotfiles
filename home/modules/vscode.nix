{ pkgs, ... }:
{
    programs.vscode = {
      enable = false; # ← Don't install, just configure
      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;
      mutableExtensionsDir = true;

      # Extensions
      extensions = (with pkgs.vscode-extensions; [
        esbenp.prettier-vscode
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
}