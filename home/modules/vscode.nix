{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = true;

    profiles.default = {
      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;

      # Extensions
      extensions = (
        with pkgs.vscode-marketplace-release;
        [
          aaron-bond.better-comments
          amazonwebservices.aws-toolkit-vscode
          astro-build.astro-vscode
          bierner.github-markdown-preview
          bierner.markdown-checkbox
          bierner.markdown-emoji
          bierner.markdown-footnotes
          bierner.markdown-mermaid
          bierner.markdown-preview-github-styles
          bierner.markdown-yaml-preamble
          bradlc.vscode-tailwindcss
          ckolkman.vscode-postgres
          dbaeumer.vscode-eslint
          dotjoshjohnson.xml
          eamodio.gitlens
          ecmel.vscode-html-css
          esbenp.prettier-vscode
          firsttris.vscode-jest-runner
          github.copilot
          github.copilot-chat
          github.vscode-github-actions
          github.vscode-pull-request-github
          jnoortheen.nix-ide
          meganrogge.template-string-converter
          ms-playwright.playwright
          ms-vsliveshare.vsliveshare
          nrwl.angular-console
          pflannery.vscode-versionlens
          pomdtr.excalidraw-editor
          quicktype.quicktype
          redhat.vscode-yaml
          skellock.just
          stripe.vscode-stripe
          tonybaloney.vscode-pets
          typescriptteam.native-preview
          upstash.context7-mcp
          wix.vscode-import-cost
          yoavbls.pretty-ts-errors
        ]
      );

      userSettings = {
        # IDE
        # "files.trimTrailingWhitespace" = true;
        "editor.formatOnSave" = true;

        #CH
        "eslint.format.enable" = true;
        "typescript.format.enable" = false;
        "[javascript]"."editor.defaultFormatter" = "dbaeumer.vscode-eslint";

        # TELEMETRY
        "aws.telemetry" = false;
        "telemetry.editStats.enabled" = false;
        "gitlens.telemetry.enabled" = false;
        "telemetry.feedback.enabled" = false;
        "redhat.telemetry.enabled" = false;
        "stripe.telemetry.enabled" = false;

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
